function evaluate(agg_data, group_vars=[:model, :fold, :split])
    res = groupby(agg_data, vcat([:ym], group_vars)) |>
        x -> combine(
            x,
            :y .=> mean => :y,
            :layer .=> unique => :layer,
            :indicator .=> unique => :indicator,
            :maturity .=> unique => :maturity,
            [:yhat, :nrow] => ((y,w) -> mean(y,Weights(w))) => :yhat
        ) |>
        x -> groupby(x, group_vars) |>
        x -> combine(
            x,
            :layer .=> unique => :layer,
            :indicator .=> unique => :indicator,
            :maturity .=> unique => :maturity,
            [:y, :yhat] => ((y, yhat) -> cor([y yhat])[1, 2]) => :cor,
            [:y, :yhat] => ((y, yhat) -> mse(y, yhat)) => :mse,
            [:y, :yhat] => ((y, yhat) -> rmse(y, yhat)) => :rmse
        )
    res = stack(res, [:cor, :mse, :rmse]) |>
        x -> groupby(x, [:indicator, :maturity, :layer, :split, :model, :variable]) |>
        x -> combine(x, :value => mean => :value, :value => std => :std) |>
        x -> sort(x, [:indicator, :maturity, :layer, :split, :variable, :model])
    return res
end