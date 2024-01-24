yhat = model(X')'
plt_gdp = plot(
    df_all.Date, y;
    label="Actual", color=:green,
    title="Modelling GDP Growth",
)
plot!(
    df_all.Date, yhat;
    label="Predicted", color=:green, ls=:dash,
)

λ = 1.0
Y = df_factors[:, [:spread, :level]] |> Matrix
A = encoder(X')'
W = (A'A + UniformScaling(λ)) \ A'Y
Ŷ = A * W
plt_probe = plot(
    df_all.Date, Y;
    color=[:blue :orange],
    label=["Spread" "Level"],
    title="Linear Probe"
)
plot!(
    df_all.Date, Ŷ;
    color=[:blue :orange], ls=:dash,
    label=["Spread (predicted)" "Level (predicted)"]
)
plt = plot(plt_gdp, plt_probe, layout=(2, 1), size=(800, 600), left_margin=5mm)
savefig(plt, joinpath(FIGURE_DIR, "dl.png"))