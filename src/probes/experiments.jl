using AlgebraOfGraphics
using CairoMakie
using CSV
using DataFrames
using Dates
import Plots
using Statistics
using StatsBase: cor, Weights
using Transformers
using TrillionDollarWords

include("utils.jl")
include("run_models.jl")
include("evaluation.jl")
include("plotting.jl")
include("attack_probe.jl")

# All data:
all_data = load_all_data()

# Setup:
save_dir = "results"
interim_dir = joinpath(save_dir, "interim")
ispath(interim_dir) || mkdir(interim_dir)
all_saved = sort(parse.(Int, filter.(isdigit, readdir(interim_dir))))
last_saved = length(all_saved) > 0 ? maximum(all_saved) : 0

# Parameter grid:
n_pcs = [nothing, 128]
use_head = [false, true]
indicator = ["PPI", "CPI", "UST"]
maturity = ["1 Mo", "1 Yr", "10 Yr"]
layer = 1:24
grids = []
for ind in indicator
    for (i,_head) in enumerate(use_head)
        _mat = ind != "UST" ? [missing] : maturity
        _layer = _head ? [25] : layer
        grid = Base.Iterators.product(_head, _mat, _layer, n_pcs) |> 
            collect |>
            x -> DataFrame(vec(x), [:use_head, :maturity, :layer, :n_pc])
        grid.indicator .= ind
        push!(grids, grid)
    end
end
grid = vcat(grids...)

# Run the models:
results = []
for (i, row) in enumerate(eachrow(grid))
    if i <= last_saved
        _results = CSV.read(joinpath(interim_dir, "results_$i.csv"), DataFrame)
    else
        println("Running models for experiment $i of $(nrow(grid))")
        _results = run_models(
            all_data; 
            indicator=row.indicator, 
            maturity=row.maturity, 
            layer=row.layer, 
            use_head=row.use_head,
            n_pc=row.n_pc,
        )
        CSV.write(joinpath(interim_dir, "results_$i.csv"), _results)
    end
    push!(results, _results)
end
results = vcat(results...)

# Save the results:
CSV.write(
    joinpath(save_dir, "results.csv"), results, 
    append=ifelse(isfile(joinpath(save_dir, "results.csv")), true, false)
)

# Evaluate the results:
results = CSV.read(joinpath(save_dir, "results.csv"), DataFrame)
gdf = groupby(results, [:indicator, :maturity, :layer]) 
df_evals = vcat([evaluate(DataFrame(g)) for g in gdf]...)
CSV.write(joinpath(save_dir, "evaluations.csv"), df_evals)

# Plot the results:
ispath(joinpath(save_dir, "figures")) || mkdir(joinpath(save_dir, "figures"))
df_evals = CSV.read(joinpath(save_dir, "evaluations.csv"), DataFrame)
gdf = groupby(df_evals, [:indicator, :maturity, :n_pc]) 
axis = (width=225, height=225)
for g in gdf
    g = DataFrame(g)
    i = g.indicator[1]
    m = g.maturity[1] |> x -> ismissing(x) ? "" : " ($x)"
    n_pc = g.n_pc[1] |> x -> ismissing(x) ? "" : " (n_pc=$x)"
    title = "$i$m$n_pc"
    plt = plot_measures(g, axis=axis)
    save(joinpath(save_dir, "figures", "measures_$title.png"), plt, px_per_unit=3) 
end

# Attack probe:
tfm = load_model(; load_head=false)
n_pc = 128
layer = 24
ispath(joinpath(save_dir, "attacks")) || mkpath(joinpath(save_dir, "attacks"))
attack_sentence_dir = "results/attacks/sentences"
ispath(attack_sentence_dir) || mkpath(attack_sentence_dir)
use_all = false
prefx = use_all ? "all_" : ""
compute_embeddings = true

high_inf_text = readlines(joinpath(attack_sentence_dir, "$(prefx)high_inf.txt"))[1]
high_inf_query = split(high_inf_text, ";") |>
    x -> String.(x)

hawk_text = readlines(joinpath(attack_sentence_dir, "$(prefx)hawk.txt"))[1]
hawk_query = split(hawk_text, ";") |>
    x -> String.(x)

low_inf_text = readlines(joinpath(attack_sentence_dir, "$(prefx)low_inf.txt"))[1]
low_inf_query = split(low_inf_text, ";") |>
    x -> String.(x)

dove_text = readlines(joinpath(attack_sentence_dir, "$(prefx)dove.txt"))[1]
dove_query = split(dove_text, ";") |>
    x -> String.(x)

queries = zip([high_inf_query, hawk_query, low_inf_query, dove_query], ["high_inf", "hawk", "low_inf", "dove"])

# Embed the queries:
queries_embedded = []
if compute_embeddings
    Threads.@threads for (q, cat) in collect(queries)
        println("Embedding queries for $cat on thread $(Threads.threadid())")
        embedding = []
        for i in collect(eachindex(q))
            push!(embedding, embed_text(tfm, [q[i]]))
            println("$i/$(length(q)) done on thread $(Threads.threadid())")
        end
        embedding = vcat(embedding...)
        push!(queries_embedded, (q, embedding, cat))
    end
    for (query, embedding, name) in queries_embedded
        CSV.write(joinpath(save_dir, "attacks", "$(prefx)attack_$name.csv"), DataFrame(embedding, :auto))
    end
else
    for (query, name) in queries
        embedding = CSV.read(joinpath(save_dir, "attacks", "$(prefx)attack_$name.csv"), DataFrame) |> Matrix
        push!(queries_embedded, (query, embedding, name))
    end
end

# Predict from the probes:
indicators = [
    ("CPI", missing),
    ("PPI", missing),
    ("UST", "1 Mo"),
    ("UST", "1 Yr"),
    ("UST", "10 Yr"),
]

predictions = []
for (ind, mat) in indicators
    ind_mat = ismissing(mat) ? ind : "$ind ($mat)"
    println("Running attacks for $ind_mat")
    # Get the data and models:
    agg_data, probes, probe_data = run_models(
        all_data;
        n_pc=n_pc,
        return_meta=true,
        layer=layer,
        indicator=ind,
        maturity=mat,
    )
    _mod, X, Σ, V = get_best_probe(agg_data, probes, probe_data)
    d = size(X, 2)
    df_pred = []
    mom_val = median([mean(_mod(randn(1000, d))) for i in 1:10000])
    for (query, embedding, name) in queries_embedded
        df = DataFrame(
            query=query,
            level=embedding_to_probe(
                _mod, embedding; 
                n_pc=n_pc, Σ=Σ, V=V
            ) .- mom_val,
            sentence=1:length(query),
            cat=name,
            dir=name ∈ ["high_inf", "hawk"] ? "Inflation" : "Deflation",
            topic=name ∈ ["high_inf", "low_inf"] ? "Prices" : "Birds",
            indicator=ind_mat
        )
        push!(df_pred, df)
    end
    df_pred = vcat(df_pred...)
    push!(predictions, df_pred)
end
predictions = vcat(predictions...)

plt_inflation = plot_attack(filter(x -> x.indicator == "CPI", predictions))
plt_all = plot_attack(predictions)

save(joinpath(save_dir, "figures", "$(prefx)attack_inflation.png"), plt_inflation, px_per_unit=3)
save(joinpath(save_dir, "figures", "$(prefx)attack_all_measures.png"), plt_all, px_per_unit=3)