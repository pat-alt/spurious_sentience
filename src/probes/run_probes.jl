using DataFrames
using Dates
using Plots
using TrillionDollarWords

include("utils.jl")

# All data:
all_data = load_all_data()

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

layer = 1
X, y = prepare_probe(mkt_data; layer=layer)

# Run the probe:
mod = probe(X,y)
yhat = mod(X)

# Run the baseline:
agg_data = groupby(mkt_data, :ym) |>
    x -> combine(x, :value .=> mean; renamecols=false)
_y = agg_data.value
p = 5
mod_bl, _X = ar(_y; l=p)
y_bl = mod_bl(_X[:,2:end])
agg_data.y_bl .= y_bl

# Save the results:
mkt_data[:,:yhat] .= yhat
agg_data_probe = groupby(mkt_data, :ym) |>
    x -> combine(x, :yhat .=> mean; renamecols=false) 

# Merge the results:
agg_data = innerjoin(agg_data, agg_data_probe, on=:ym)

# Plot the results:
plt = plot(
    [agg_data.value agg_data.yhat agg_data.y_bl], 
    label=[indicator "Probe" "AR($p)"], 
    legend=:topleft, 
    xlabel="Year", 
    ylabel=indicator
)
display(plt)

# Score the results:
DataFrame(
    indicator = indicator,
    model = ["Probe", "AR($p)"],
    rmse = [rmse(mod, X, y), rmse(mod_bl, _X[:,2:end], _y)],
    mse = [mse(mod, X, y), mse(mod_bl, _X[:,2:end], _y)]
)