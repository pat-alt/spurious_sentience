using DataFrames
using Dates
using Plots
using TrillionDollarWords

include("utils.jl")
use_clf = false

# All data:
all_data = load_all_data()
model = load_model(;use_head=true)
clf = model.mod.cls

# Inflation:
indicator = "PPI"
mkt_data = subset(all_data, :indicator => x -> x.==indicator)
transform!(mkt_data, :date => ByRow(x -> Dates.yearmonth(x)) => :ym)
mkt_data = groupby(mkt_data, :ym) |>
    x -> select(x, [:ym, :value]) |>
    unique |>
    x -> transform(x, :value => lag => :value_lag) |>
    x -> select(x, Not(:value)) |>
    x -> innerjoin(x, mkt_data, on=:ym) |>
    x -> transform(x, [:value, :value_lag] => ByRow((y,yl) -> log(y)-log(yl)) => :growth) 
replace!(mkt_data.growth, Inf => 0.0)
select!(mkt_data, Not([:value]))
rename!(mkt_data, :growth => :value)
select!(mkt_data, [:date, :ym, :sentence_id, :value])

layer = 24
X, y = prepare_probe(mkt_data; layer=layer)

if use_clf
    X = vcat([get_clf_activations(clf, x)' for x in eachrow(X)]...)
end

# Run the probe:
mod = probe(X,y)
yhat = mod(X)

# Run the baseline:
agg_data = groupby(mkt_data, :ym) |>
    x -> combine(x, :value .=> mean; renamecols=false)
_y = agg_data.value
lag_select(_y)
mod_bl, _X = ar(_y; l=p)
y_bl = mod_bl(_X[:,2:end])
agg_data.y_bl .= y_bl

# Save the results:
mkt_data[:,:yhat] .= yhat
agg_data_probe = groupby(mkt_data, :ym) |>
    x -> combine(x, :yhat .=> mean; renamecols=false) 

# Merge the results:
agg_data = innerjoin(agg_data, agg_data_probe, on=:ym)