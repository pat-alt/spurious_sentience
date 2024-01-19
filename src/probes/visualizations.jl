# Plot the results:
plt = plot(
    [agg_data.value agg_data.yhat agg_data.y_bl],
    label=[indicator "Probe" "AR($p)"],
    alpha=[0.2 1.0 1.0],
    legend=:topleft,
    xlabel="Year",
    ylabel=indicator
)