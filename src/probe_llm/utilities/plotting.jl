"""
    plot_ts(
        agg_data::DataFrame;
        alpha=[0.2 1.0 1.0],
        legend=:topleft,
        xlabel="Year",
        kwrgs...
    )

Plot the time series of the actual and predicted values for the probe and the AR model.
"""
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
    plt = Plots.plot(
        dates,
        ts;
        label=[measure_name "AR($p)" "Probe (layer $layer)"],
        ylabel=measure_name,
        alpha=alpha,
        legend=legend,
        xlabel=xlabel,
        kwrgs...
    )
    return plt
end


"""
    plot_measures(
        df::DataFrame;
        axis=(width=225, height=225),
        variables=["cor", "mse", "rmse"],
        splits=["train", "test"],
        indicators=["CPI", "PPI", "UST"]

    )

Plot the evaluation measures against the layer number for a set of models for a single variable. The dataframe should contain only one variable.
"""
function plot_measures(
    df::DataFrame;
    axis=(width=225, height=225),
    variable="rmse",
    splits=["train", "test"],
    indicators=["CPI", "PPI", "UST"],
    models=["y_bl", "y_probe"],
    plot_interval=true,
)

    # Filter the data:
    df = filter(x -> x.split ∈ splits, df)
    df = filter(x -> x.indicator ∈ indicators, df)
    df = filter(x -> x.variable == variable, df)
    df = filter(x -> x.model ∈ models, df)

    # Upper and lower bounds:
    df = transform(df, [:value, :std] => ByRow((x, s) -> (x + s, x - s)) => [:lb, :ub])
    df = df[.!isnan.(df.value), :]

    # Transform the indicator and maturity:
    transform!(df, [:indicator, :maturity] => ByRow((ind, mat) -> ismissing(mat) ? ind : "$(ind) ($mat)") => :indicator)

    df = unique(df, [:indicator, :layer, :split, :n_pc, :model, :variable])

    # Plot the results:
    if plot_interval
        plt = data(df) * mapping(
            :layer, :value,
            lower=:lb, upper=:ub,
            row=:split,
            col=:indicator,
            color=:model => x -> x == "y_bl" ? "AR" : "Probe",
        )
        layer = visual(LinesFill)
    else
        plt = data(df) * mapping(
            :layer, :value,
            row=:split,
            col=:indicator,
            color=:model => x -> x == "y_bl" ? "AR" : "Probe",
        )
        layer = visual(Lines)
    end
    plt = draw(
        layer * plt,
        facet=(; linkyaxes=:none),
        axis=axis
    )

end

"""
    plot_measures_for_ind(
        df::DataFrame;
        axis=(width=225, height=225)
    )

Plot the evaluation measures against the layer number for a set of models for a single indicator. The dataframe should contain only one indicator and one maturity.
"""
function plot_measures_for_ind(
    df::DataFrame;
    axis=(width=225, height=225),
    splits=["train", "test"],
    models=["y_bl", "y_probe"],
    plot_interval=true,
)

    @assert length(unique(df.indicator)) == 1 "The dataframe should contain only one indicator."
    @assert length(unique(df.maturity)) == 1 "The dataframe should contain only one maturity."

    # Filter the data:
    df = filter(x -> x.split ∈ splits, df)
    df = filter(x -> x.model ∈ models, df)

    # Title:
    indicator = df.indicator[1]
    maturity = df.maturity[1]
    if !ismissing(maturity)
        title = "$indicator ($maturity)"
    else
        title = "$indicator"
    end

    # Upper and lower bounds:
    df = transform(df, [:value, :std] => ByRow((x, s) -> (x + s, x - s)) => [:lb, :ub])
    df = df[.!isnan.(df.value), :]

    # Plot the results:
    if plot_interval 
        plt = data(df) * mapping(
            :layer, :value, 
            lower=:lb, upper=:ub,
            row=:split,
            col=:variable, 
            color=:model => x -> x=="y_bl" ? "AR" : "Probe",
        )
        layer = visual(LinesFill)
    else
        plt = data(df) * mapping(
            :layer, :value,
            row=:split,
            col=:variable,
            color=:model => x -> x=="y_bl" ? "AR" : "Probe",
        )
        layer = visual(Lines)
    end
    plt = draw(
        layer * plt, 
        facet=(; linkyaxes=:none),
        axis=axis
    )
    plt.figure[0, :] = Label(plt.figure, title, fontsize=20)
    return plt
end

"""
    plot_attack(df_pred::DataFrame)

Plot the attack results.
"""
function plot_attack(df_pred::DataFrame)

    if length(unique(df_pred.indicator)) == 1
        _map = mapping(
            :dir => "Direction",
            :level => "f(x) - 𝔼[f(ϵ)]",
            color=:topic => "Topic",
            dodge=:topic => "Topic",
        )
    else
        _map = mapping(
            col=:indicator,
            :dir => "Direction",
            :level => "f(x) - 𝔼[f(ϵ)]",
            color=:topic => "Topic",
            dodge=:topic => "Topic",
        )
    end

    df_plt = data(df_pred) * _map
    layers = visual(BoxPlot)
    box_plt = layers * df_plt
    hline_plt = mapping([0], [0]) * visual(ABLines)
    plt = draw(
        hline_plt + box_plt,
        facet=(; linkyaxes=:none),
        axis=(width=300, height=300)
    )
end