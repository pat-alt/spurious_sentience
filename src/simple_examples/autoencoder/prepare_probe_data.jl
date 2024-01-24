df_long = @pivot_longer(df_all, -(Date:quarter)) |>
    x -> @arrange(x, Date) |>
    x -> @select(x, -(year:quarter))

df_spread = df_long |>
    x -> @filter(x, variable=="0.25" || variable=="10.0") |>
    x -> @mutate(x, variable=ifelse(variable=="0.25","short","long")) |>
    x -> @pivot_wider(x, names_from=variable, values_from=value) |>
    x -> @mutate(x, spread=long-short) |>
    x -> @select(x, Date, spread)

df_level = @group_by(df_long, Date) |>
    x -> @mutate(x, level=sum(value)/length(value)) |>
    x -> @ungroup(x) |>
    x -> @select(x, Date, level) |>
    unique

df_factors = @full_join(df_spread, df_level) 