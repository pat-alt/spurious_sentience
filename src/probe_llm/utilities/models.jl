"""
    function run_models(
        all_data; 
        indicator="PPI", 
        maturity=missing, 
        layer=24, 
        use_head=false,
        n_folds::Int=5,
        λ::Real=0.1,
        min_train_prp::Float64=0.75,
        n_pc::Union{Nothing,Int}=nothing,
        return_meta::Bool=false,
    )

Run the probe experiment for a given set of parameters. Runs the baseline AR model on the aggregated data and the probe on the individual sentences. Both models are run for each cross-validation fold using an expanding window scheme. The results are aggregated over the folds.
"""
function run_models(
    all_data; 
    indicator="PPI", 
    maturity=missing, 
    layer=24, 
    use_head=false,
    n_folds::Int=5,
    λ::Real=0.1,
    min_train_prp::Float64=0.75,
    n_pc::Union{Nothing,Int}=nothing,
    return_meta::Bool=false,
)

    # Prepare market data:
    mkt_data = prepare_mkt_data(all_data, indicator, maturity) |>
        x -> sort(x, [:ym, :event_type, :speaker])
    time_stamps = unique(sort(mkt_data.ym))
    ts_splits = time_series_split(
        time_stamps; 
        n_folds=n_folds, 
        return_vals=true, 
        min_train_prp=min_train_prp
    ) |> collect

    # Prepare the data for the probe:
    if use_head
        X_probe, y_probe = prepare_probe(mkt_data)
        model = load_model(; use_head=use_head)
        clf = model.mod.cls
        X_probe = vcat([get_clf_activations(clf, x)' for x in eachrow(X_probe)]...)
    else
        X_probe, y_probe = prepare_probe(mkt_data; layer=layer)
    end

    mkt_data.layer .= layer

    # Run models for each split:
    res = []
    probes = []
    probe_data = []
    for (i, (train, test)) in enumerate(ts_splits)
        _mkt_data = deepcopy(mkt_data) |>
            x -> sort(x, [:sentence_id, :ym, :event_type, :speaker])
        # Run the baseline on the aggregated data:
        agg_data = groupby(_mkt_data, :ym) |>
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

        # Assign the split (train/test):
        transform!(_mkt_data, :ym => ByRow(x -> in(x, train) ? "train" : "test") => :split)
        sort!(_mkt_data, [:sentence_id, :ym, :event_type, :speaker])

        # Run the probe:
        X_train, y_train = X_probe[_mkt_data.split .== "train", :], y_probe[_mkt_data.split .== "train"]
        # Reduce the dimensionality of the probe data:
        if !isnothing(n_pc)
            # Run PCA on the training data:
            U, Σ, V = svd(X_train)
            X_train = U[:, 1:n_pc]
            # Project all probe data:
            X_all = X_probe * inv(diagm(Σ) * V') |>
                x -> x[:, 1:n_pc]
            push!(probe_data, (X=X_train, Σ=Σ, V=V))
        else
            push!(probe_data, (X=X_train,))
        end
        mod = probe(X_train, y_train; λ=λ)
        push!(probes, mod)
        yhat = mod(X_all)
        _mkt_data[:, :y_probe] .= yhat

        # Aggregate the probe results:
        agg_data_probe =
            groupby(_mkt_data, [:ym, :event_type, :speaker, :indicator, :layer]) |>
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
        agg_data.n_pc .= isnothing(n_pc) ? missing : n_pc

        # Stack:
        agg_data = stack(agg_data, [:y_probe, :y_bl], variable_name=:model, value_name=:yhat) |>
            x -> sort(x, [:ym, :model])

        push!(res, agg_data)
    end

    res = vcat(res...)

    if return_meta
        return res, probes, probe_data
    else
        return res
    end

end

