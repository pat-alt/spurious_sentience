# Parameters
n_pcs = [nothing, 128]
use_head = [false, true]
indicator = ["PPI", "CPI", "UST"]
maturity = ["1 Mo", "1 Yr", "10 Yr"]
layer = 1:24
grids = []

# Set up a grid of parameters:
for ind in indicator
    for (i, _head) in enumerate(use_head)
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