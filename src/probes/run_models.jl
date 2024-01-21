function run_models(
    all_data; 
    indicator="PPI", 
    maturity=missing, 
    layer=24, 
    use_head=false,
    n_folds::Int=1,
)

    # Prepare market data:
    mkt_data = prepare_mkt_data(all_data, indicator, maturity) |>
        x -> sort(x, [:ym, :event_type, :speaker])
    time_stamps = unique(sort(mkt_data.ym))
    ts_splits = time_series_split(time_stamps; n_folds=n_folds, return_vals=true) |> collect

    # Run models for each split:
    res = []
    for (i, (train, test)) in enumerate(ts_splits)
        
        println("Running experiment $i of $(size(ts_splits)[1])")

        # Run the baseline on the aggregated data:
        agg_data = groupby(mkt_data, :ym) |>
            x -> combine(x, :value .=> mean; renamecols=false) |>
            x -> sort(x, :ym) 
        y = agg_data.value
        # Assign the split (train/test):
        transform!(agg_data, :ym => ByRow(x -> in(x, train) ? "train" : "test") => :split)
        y_train = agg_data[agg_data.split .== "train", :value]
        # Select the optimal lag based on the training data and fit the model:
        p = lag_select(y_train)
        mod_bl, _ = ar(y_train; l=p)
        # Predict on the test data:
        X = prepare_ar(y; l=p)
        y_bl = mod_bl(X)
        agg_data.y_bl .= y_bl
        agg_data.p .= p
        agg_data.fold .= i

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

        # Assign the split (train/test):
        transform!(mkt_data, :ym => ByRow(x -> in(x, train) ? "train" : "test") => :split)

        # Run the probe:
        X_train, y_train = X[mkt_data.split .== "train", :], y[mkt_data.split .== "train"]
        mod = probe(X_train, y_train)
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

        push!(res, agg_data)
    end

    res = vcat(res...)

    return res

end

