function evaluate(agg_data, group_vars=[:model])
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
            [:y, :yhat] => ((y, yhat) -> StatsBase.cor([y yhat])[1, 2]) => :cor,
            [:y, :yhat] => ((y, yhat) -> mse(y, yhat)) => :mse,
            [:y, :yhat] => ((y, yhat) -> rmse(y, yhat)) => :rmse,
            [:y, :yhat] => ((y, yhat) -> r2(y, yhat)) => :r2,
        )
    return res
end