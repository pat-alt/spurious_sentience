ts = unstack(agg_data, [:ym, :y], :model, :yhat) |>
    x -> select(x, Not([:ym])) |>
    Matrix

dates = [Date(y,m) for (y,m) in unique(agg_data.ym)]

# Plot the results:
plt = plot(
    dates,
    ts,
    label=[indicator "AR($p)" "Probe"],
    alpha=[0.2 1.0 1.0],
    legend=:topleft,
    xlabel="Year",
    ylabel=indicator
)