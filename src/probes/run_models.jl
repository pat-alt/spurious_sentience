using DataFrames
using Dates
using Plots
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
lag_select(_y)
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
mkt_data[:, :yhat] .= yhat

# Aggregate the probe results:
agg_data_probe = groupby(mkt_data, :ym) |>
    x -> combine(x, :yhat .=> mean; renamecols=false) 

# Merge the results:
agg_data = innerjoin(agg_data, agg_data_probe, on=:ym)