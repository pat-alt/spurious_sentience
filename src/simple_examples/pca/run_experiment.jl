df = CSV.read("data/ust_yields.csv", DataFrame) |>
    x -> @pivot_longer(x, -Date) |>
    x -> @mutate(x, variable=to_year(variable)) |>
    x -> @mutate(x, year=Dates.year(Date)) |>
    x -> @mutate(x, quarter=Dates.quarter(Date)) |>
    x -> @mutate(x, Date=Dates.format(Date, "yyyy-mm-dd")) |>
    x -> @arrange(x, Date) |>
    x -> @fill_missing(x, "down")
ylims = extrema(skipmissing(df.value))

# Peak-crisis:
onset_date = "2007-02-27"
plt_df = df[df.Date .== onset_date, :]
plt = plot(
    plt_df.variable, plt_df.value;
    label="", color=:blue,
    xlabel="Maturity (years)", ylabel="Yield (%)",
)
scatter!(
    plt_df.variable, plt_df.value;
    label="", color=:blue, alpha=0.5,
    ylims=(0,6)
)
display(plt)

# Post-crisis:
aftermath_date = "2009-04-20"
plt_df = df[df.Date .== aftermath_date, :]
plt = plot(
    plt_df.variable, plt_df.value;
    label="", color=:blue,
    xlabel="Maturity (years)", ylabel="Yield (%)",
)
scatter!(
    plt_df.variable, plt_df.value;
    label="", color=:blue, alpha=0.5,
    ylims=(0,6)
)
display(plt)

# PCA:
df_wide = @select(df, Date, variable, value) |>
    x -> @pivot_wider(x, names_from = variable, values_from = value) |>
    x -> dropmissing(x)
X = @select(df_wide, -Date) |> Matrix
U, Σ, V = svd(X)
dates = Date.(df_wide.Date)
tick_years = Date.(unique(Dates.year.(dates)))
date_tick = Dates.format.(tick_years, "yyyy")
n_pc = 2
plt_pc = plot(
    dates,
    .-U[:,1:n_pc],
    label=["PC $i" for i in 1:n_pc] |> permutedims,
    size=(1000, 300),
    ylims=(-0.015,0.03),
    legend=:topright
)
plot!(xticks=(tick_years,date_tick), xtickfontsize=6, yaxis=(formatter=y->@sprintf("%.2f",y)))
vline!(Date.([onset_date]), ls=:solid, color=:black, label="Onset of GFC")
vline!(Date.([aftermath_date]), ls=:dash, color=:black, label="Aftermath of GFC")

# Level:
df_level = @group_by(df, Date) |>
    x -> @mutate(x, level=sum(value)/length(value)) |>
    x -> @ungroup(x) |>
    x -> @select(x, Date, level)

# Spreads:
df_spread = @filter(df, variable==0.25 || variable==10) |>
    x -> @select(x, -(year:quarter)) |>
    x -> @mutate(x, variable=ifelse(variable==0.25,"short","long")) |>
    x -> @pivot_wider(x, names_from=variable, values_from=value) |>
    x -> @mutate(x, spread=long-short) |>
    x -> @select(x, Date, spread)

# Plot:
plt_mat = @full_join(df_level, df_spread) |> 
    dropmissing |> 
    unique |>
    x -> @select(x, -Date) |>
    Matrix
plt_obs = plot(
    dates,
    plt_mat,
    label=["Level" "Spread"],
    size=(1000, 300),
    ylims=(-3,9),
    legend=:topright,
    ylab="Yield (%)"
)
plot!(xticks=(tick_years,date_tick), xtickfontsize=6, yaxis=(formatter=y->@sprintf("%.2f",y)))
vline!(Date.([onset_date]), ls=:solid, color=:black, label="Onset of GFC")
vline!(Date.([aftermath_date]), ls=:dash, color=:black, label="Aftermath of GFC")

plt = plot(plt_pc, plt_obs, layout=(2,1), size=(1000, 400), left_margin=5mm, bottom_margin=5mm)
savefig(plt, joinpath(FIGURE_DIR, "pca.png"))

