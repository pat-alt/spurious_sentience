function plot_ts(
    agg_data::DataFrame;
    alpha=[0.2 1.0 1.0],
    legend=:topleft,
    xlabel="Year",
    kwrgs...
)
    
    # Collect metadata:
    indicator = agg_data.indicator[1]
    maturity = agg_data.maturity[1]
    layer = agg_data.layer[1]
    p = agg_data.p[1]

    # Aggregate the results:
    ts = groupby(agg_data, [:ym, :model]) |>
        x -> combine(
            x,
            :y .=> mean => :y,
            [:yhat, :nrow] => ((y, w) -> mean(y, Weights(w))) => :yhat
        ) |>
        x -> unstack(x, [:ym, :y], :model, :yhat) |>
        x -> select(x, Not([:ym])) |>
        Matrix

    # Collect the dates:
    dates = [Date(y,m) for (y,m) in unique(agg_data.ym)]

    # Plot the results:
    measure_name = indicator
    if !ismissing(maturity)
        measure_name = "$measure_name ($maturity)"
    end
    plt = plot(
        dates,
        ts,
        label=[measure_name "AR($p)" "Probe (layer $layer)"],
        ylabel=measure_name,
        alpha=alpha,
        legend=legend,
        xlabel=xlabel,
        kwrgs...
    )
    return plt
end