df_gdp_full = CSV.read("data/gdp.csv", DataFrame) |>
    x -> @rename(x, Date=DATE, gdp=GDPC1) |>
    x -> @mutate(x, gdp_l1=lag(gdp)) |>
    x -> @mutate(x, growth=log(gdp)-log(gdp_l1)) |>
    x -> @select(x, Date, growth) |>
    x -> @mutate(x, year=Dates.year(Date)) |>
    x -> @mutate(x, quarter=Dates.quarter(Date)) 
df_gdp = df_gdp_full |>
    x -> @filter(x, year <= 2018)

df_yields_qtr = @group_by(df, year, quarter, variable) |>
    x -> @mutate(x, value=mean(value)) |>
    x -> @ungroup(x) |>
    x -> @select(x, -Date) |>
    unique

df_all = @inner_join(df_gdp, df_yields_qtr, (year, quarter)) |> 
    x -> @pivot_wider(x, names_from=variable, values_from=value) |>
    dropmissing

y = df_all.growth |> 
    x -> Float32.(x)
X = @select(df_all, -(Date:quarter)) |> 
    Matrix |>
    x -> Float32.(x) |>
    x -> Flux.normalise(x; dims=1)

# Plot:
p_gdp = plot(
    df_all.Date, y;
    label="", color=:blue,
    size=(800,200),
    ylabel="GDP Growth (log difference)"
)
p_yields = plot(
    df_all.Date, X;
    label="", color=:blue,
    ylabel="Yield (standardized))",
    legend=:bottomright,
    alpha=0.5,
    size=(800,400)
)
plot(p_gdp, p_yields, layout=(2,1), size=(800, 600), left_margin=5mm, dpi=300)