yhat = model(X')'

dates = Date.(df_all.Date)
tick_years = Date.(unique(Dates.year.(dates)))
tick_years = range(tick_years[1], tick_years[end], step=Year(5))
date_tick = Dates.format.(tick_years, "yyyy")

plt_gdp = plot(
    df_all.Date, y;
    label="g", color=:green,
    size=(1000,200),
    dpi=300
)
plot!(
    df_all.Date, yhat;
    label="ĝ", color=:green, ls=:dash,
)
plot!(xticks=(tick_years, date_tick), yaxis=(formatter = y -> @sprintf("%.2f", y)))
savefig(plt_gdp, joinpath(FIGURE_DIR, "gdp.png"))

λ = 1.0
Y = df_factors[:, [:spread, :level]] |> Matrix
A = encoder(X')'
W = (A'A + UniformScaling(λ)) \ A'Y
Ŷ = A * W

plt_probe = plot(
    dates, Y;
    color=[:blue :orange],
    label=["yₛ" "yₗ"],
    size=(1000, 200),
    dpi=300
)
plot!(
    dates, Ŷ;
    color=[:blue :orange], ls=:dash,
    label=["ŷₛ" "ŷₗ"]
)
plot!(xticks=(tick_years, date_tick), yaxis=(formatter = y -> @sprintf("%.2f", y)))
savefig(plt_probe, joinpath(FIGURE_DIR, "factor_probe.png"))

# Combine:
plt = plot(
    plt_gdp, plt_probe, layout=(1, 2), 
    size=(1000, 200), left_margin=5mm,
    dpi=300
)
savefig(plt, joinpath(FIGURE_DIR, "dl.png"))