function run_models(
    all_data; 
    indicator="PPI", 
    maturity=missing, 
    layer=24, 
    use_head=false,
)

    # Prepare market data:
    mkt_data = prepare_mkt_data(all_data, indicator, maturity)

    # Run the baseline on the aggregated data:
    agg_data = groupby(mkt_data, :ym) |>
        x -> combine(x, :value .=> mean; renamecols=false)
    _y = agg_data.value
    p = lag_select(_y)
    mod_bl, _X = ar(_y; l=p)
    y_bl = mod_bl(_X)
    agg_data.y_bl .= y_bl
    agg_data.p .= p

    # Prepare the data for the probe:
    if use_head
        X, y = prepare_probe(mkt_data)
        model = load_model(; use_head=use_head)
        clf = model.mod.cls
        X = vcat([get_clf_activations(clf, x)' for x in eachrow(X)]...)
    else
        X, y = prepare_probe(mkt_data; layer=layer)
    end
    mkt_data.layer .= layer

    # Run the probe:
    mod = probe(X,y)
    yhat = mod(X)
    mkt_data[:, :y_probe] .= yhat

    # Aggregate the probe results:
    agg_data_probe =
        groupby(mkt_data, [:ym, :event_type, :speaker, :indicator, :layer]) |>
        x -> combine(
            x, 
            :y_probe .=> mean => :y_probe,
            nrow
        ) |>
        x -> sort(x, [:ym, :event_type, :speaker])

    # Merge the results:
    agg_data = innerjoin(agg_data, agg_data_probe, on=:ym)
    rename!(agg_data, :value => :y)
    agg_data.indicator .= indicator
    agg_data.maturity .= maturity

    # Stack:
    agg_data = stack(agg_data, [:y_probe, :y_bl], variable_name=:model, value_name=:yhat) |>
        x -> sort(x, [:ym, :model])

    return agg_data
end

