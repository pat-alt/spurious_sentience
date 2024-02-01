"""
    evaluate(
        agg_data; 
        group_vars=[:model, :fold, :split, :n_pc],
        agg_vars=[:indicator, :maturity, :layer, :split, :n_pc, :variable, :model]
    )

Evaluate the results of a probe experiment. The input data should be aggregated over the cross-validation folds.
"""
function evaluate(
    agg_data; 
    group_vars=[:model, :fold, :split, :n_pc],
    agg_vars=[:indicator, :maturity, :layer, :split, :n_pc, :variable, :model]
)
    res = groupby(agg_data, vcat([:ym], group_vars)) |>
        x -> combine(
            x,
            :y .=> mean => :y,
            :layer .=> unique => :layer,
            :indicator .=> unique => :indicator,
            :maturity .=> unique => :maturity,
            :n_pc .=> unique => :n_pc,
            [:yhat, :nrow] => ((y,w) -> mean(y,Weights(w))) => :yhat
        ) |>
        x -> groupby(x, group_vars) |>
        x -> combine(
            x,
            :layer .=> unique => :layer,
            :indicator .=> unique => :indicator,
            :maturity .=> unique => :maturity,
            :n_pc .=> unique => :n_pc,
            [:y, :yhat] => ((y, yhat) -> cor([y yhat])[1, 2]) => :cor,
            [:y, :yhat] => ((y, yhat) -> mse(y, yhat)) => :mse,
            [:y, :yhat] => ((y, yhat) -> rmse(y, yhat)) => :rmse,
            [:y, :yhat] => ((y, yhat) -> mda(y, yhat)) => :mda,
        )
    res = stack(res, [:cor, :mse, :rmse, :mda]) |>
        x -> groupby(x, agg_vars) |>
        x -> combine(x, :value => mean => :value, :value => std => :std) |>
        x -> sort(x, agg_vars)
    return res
end