using AlgebraOfGraphics
using CairoMakie
using CSV
using DataFrames
using Dates
using Plots
using Statistics
using StatsBase: cor, Weights
using TrillionDollarWords

include("utils.jl")
include("run_models.jl")
include("evaluation.jl")
include("plotting.jl")

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
    i <= last_saved && continue
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
gdf = groupby(df_evals, [:indicator, :maturity]) 
axis = (width=225, height=225)
for g in gdf
    g = DataFrame(g)
    i = g.indicator[1]
    m = g.maturity[1]
    if !ismissing(m)
        title = "$i ($m)"
    else
        title = i
    end
    plt = plot_measures(g, axis=axis)
    save(joinpath(save_dir, "figures", "measures_$title.png"), plt, px_per_unit=3) 
end