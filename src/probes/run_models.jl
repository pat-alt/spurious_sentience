using DataFrames
using Dates
using Plots
using StatsBase: cor
using TrillionDollarWords

include("utils.jl")

# All data:
all_data = load_all_data()

# Parameters:
use_clf = false
indicator = "PPI"
maturity = nothing
layer = 24

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

# Prepare the data for the probe:
X, y = prepare_probe(mkt_data; layer=layer)
if use_clf
    model = load_model(; use_head=use_head)
    clf = model.mod.cls
    X = vcat([get_clf_activations(clf, x)' for x in eachrow(X)]...)
end

# Run the probe:
mod = probe(X,y)
yhat = mod(X)
mkt_data[:, :y_probe] .= yhat
mkt_data[:, :layer] .= layer

# Aggregate the probe results:
agg_data_probe = groupby(mkt_data, [:ym]) |>
    x -> combine(
        x, 
        :y_probe .=> mean => :y_probe,
        nrow
    )

# Merge the results:
agg_data = innerjoin(agg_data, agg_data_probe, on=:ym)
rename!(agg_data, :value => :y)
agg_data.indicator .= indicator
agg_data.maturity .= maturity

# Stack:
agg_data = stack(agg_data, [:y_probe, :y_bl], variable_name=:model, value_name=:yhat) |>
    x -> sort(x, [:ym, :model])

# Evaluate the results:
res = groupby(agg_data, [:ym, :model]) |>
    x -> combine(
        x,
        :y .=> mean => :y,
        [:yhat, :nrow] => ((y,w) -> mean(y,Weights(w))) => :yhat
    ) |>
    x -> groupby(x, :model) |>
    x -> combine(
        x,
        [:y, :yhat] => ((y, yhat) -> StatsBase.cor([y yhat])[1, 2]) => :cor,
        [:y, :yhat] => ((y, yhat) -> mse(y, yhat)) => :mse,
        [:y, :yhat] => ((y, yhat) -> rmse(y, yhat)) => :rmse,
    )