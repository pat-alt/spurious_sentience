include("setup.jl")

# Run the models:
if RUN_MODELS
    include("run_models.jl")
end

# Evaluate the results:
if EVALUATE
    if isfile(joinpath(save_dir, "results.csv"))
        results = CSV.read(joinpath(save_dir, "results.csv"), DataFrame)
    else
        interim_results = readdir(joinpath(interim_dir))
        interim_results = interim_results[sortperm(parse.(Int, filter.(isdigit, interim_results)))]
        results = [CSV.read(joinpath(interim_dir, f), DataFrame) for f in interim_results]
        results = vcat(results...)
    end
    gdf = groupby(results, [:indicator, :maturity, :layer])
    df_evals = vcat([evaluate(DataFrame(g)) for g in gdf]...)
    CSV.write(joinpath(save_dir, "evaluations.csv"), df_evals)
end

# Plot the results:
if PLOT_PROBES
    ispath(joinpath(save_dir, "figures")) || mkdir(joinpath(save_dir, "figures"))
    df_evals = CSV.read(joinpath(save_dir, "evaluations.csv"), DataFrame)
    plt = plot_measures(
        df_evals;
        axis=(width=225, height=225),
        plot_interval=false,
        models=["y_probe"],
        splits=["test"],
    )
    gdf = groupby(df_evals, [:indicator, :maturity, :n_pc]) 
    axis = (width=225, height=225)
    for g in gdf
        g = DataFrame(g)
        i = g.indicator[1]
        m = g.maturity[1] |> x -> ismissing(x) ? "" : " ($x)"
        n_pc = g.n_pc[1] |> x -> ismissing(x) ? "" : " (n_pc=$x)"
        title = "$i$m$n_pc"
        plt = plot_measures_for_ind(g, axis=axis)
        save(joinpath(save_dir, "figures", "measures_$title.png"), plt, px_per_unit=3) 
        plt = plot_measures_for_ind(g, axis=axis, plot_interval=false, models=["y_probe"])
        save(joinpath(save_dir, "figures", "measures_probe_$title.png"), plt, px_per_unit=3)
    end
end

# Attack probe:
if RUN_ATTACKS
    include("run_attacks.jl")
end