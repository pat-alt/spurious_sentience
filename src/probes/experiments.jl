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
n_pc = 128
layer = 24
tfm = load_model(; load_head=false)

high_inf_text = "Consumer prices are at all-time highs.;Inflation is expected to rise further.;The Fed is expected to raise interest rates to curb inflation.;Excessively loose monetary policy is the cause of the inflation.;It is essential to bring inflation back to target to avoid drifting into hyperinflation territory."
high_inf_query = split(high_inf_text, ";") |>
    x -> String.(x)

hawk_text = "The number of hawks is at all-time highs.;Their levels are expected to rise further.;The Federal Association of Birds is expected to raise barriers of entry for hawks to bring their numbers back down to the target level.;Excessively loose migration policy for hawks is the likely cause of their numbers being so far above target.;It is essential to bring the number of hawks back to target to avoid drifting into hyper-hawk territory."
hawk_query = split(hawk_text, ";") |>
    x -> String.(x)

low_inf_text = "Consumer prices are at all-time lows.;Inflation is expected to fall further.;The Fed is expected to lower interest rates to boost inflation.;Excessively tight monetary policy is the cause of deflationary pressures.;It is essential to bring inflation back to target to avoid drifting into deflation territory."
low_inf_query = split(low_inf_text, ";") |>
    x -> String.(x)

dove_text = "The number of doves is at all-time lows.;Their levels are expected to fall further.;The Federal Association of Birds is expected to lower barriers of entry for doves to bring their numbers back up to the target level.;Excessively tight migration policy for doves is the likely cause of their numbers being so far below target.;It is essential to bring the numbers of doves back to target to avoid drifting into dovelation territory."
dove_query = split(dove_text, ";") |>
    x -> String.(x)

queries = zip([high_inf_query, hawk_query, low_inf_query, dove_query], ["high_inf", "hawk", "low_inf", "dove"])

# Embed the queries:
queries_embedded = [(q,embed_text(tfm, q),cat) for (q, cat) in queries]

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
    mod, mkt_data, X, Σ, V = get_best_probe(agg_data, probes, probe_data)
    df_pred = []
    avg_val = mean(mod(X))
    for (query, embedding, name) in queries_embedded
        df = DataFrame(
            query=query,
            level=embedding_to_probe(
                mod, embedding; 
                n_pc=n_pc, Σ=Σ, V=V
            ) .- avg_val,
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

plt_inflation = plot_attack(filter(x -> x.indicator == "PPI", predictions))
plt_all = plot_attack(predictions)

save(joinpath(save_dir, "figures", "attack_inflation.png"), plt_inflation, px_per_unit=3)
save(joinpath(save_dir, "figures", "attack_all.png"), plt_all, px_per_unit=3)