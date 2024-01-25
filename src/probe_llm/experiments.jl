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
    axis = (width=150, height=150)
    model = "y_probe"
    _split = "test"
    plot_interval = false
    ispath(joinpath(save_dir, "figures")) || mkdir(joinpath(save_dir, "figures"))
    df_evals = CSV.read(joinpath(save_dir, "evaluations.csv"), DataFrame)

    for _var in sort(unique(df_evals.variable))
        # Full (no PCA):
        evals_full = filter(x -> ismissing(x.n_pc), df_evals)
        plt = plot_measures(
            evals_full;
            axis=axis,
            plot_interval=plot_interval,
            model=model,
            split=_split,
            variable=_var
        )
        save(joinpath(save_dir, "figures", "$(_var)_full.png"), plt, px_per_unit=3)

        # With PCA:
        evals_pca = filter(x -> !ismissing(x.n_pc), df_evals)
        for n_pc in sort(unique(evals_pca.n_pc))
            _df = filter(x -> x.n_pc == n_pc, evals_pca)
            plt = plot_measures(
                _df;
                axis=axis,
                plot_interval=plot_interval,
                model=model,
                split=_split,
                variable=_var
            )
            save(joinpath(save_dir, "figures", "$(_var)_pca_$(n_pc).png"), plt, px_per_unit=3)
        end
    end
    
    # By indicator:
    gdf = groupby(df_evals, [:indicator, :maturity, :n_pc]) 
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
    COMPUTE_EMBEDDINGS = false
    USE_ALL_SENTENCES = false
    include("run_attacks.jl")
end