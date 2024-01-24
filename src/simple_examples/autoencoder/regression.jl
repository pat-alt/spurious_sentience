# Regress on all latent embeddings:
reg_data = DataFrame(Float64.(hcat(y, A)), ["y", ["a$i" for i in 1:size(A, 2)]...])
ols_all_latent = lm(@formula(y ~ a1 + a2 + a3 + a4 + a5 + a6), reg_data)

# Regress on best latent embeddings:
top_n = 1
pvals = coeftable(ols_all_latent).cols[4][2:end]
best_idx = findall([x in sort(pvals)[1:top_n] for x in pvals])
regressors = ["a$i" for i in best_idx]
reg_data = DataFrame(Float64.(hcat(y, A)), ["y", ["a$i" for i in 1:size(A, 2)]...])
ols_best_latent = lm(GLM.Term(:y) ~ sum(GLM.Term.(Symbol.(regressors))), reg_data)

# Simple AR(1) model:
reg_data = DataFrame(
    Float64.(hcat(y, lag(y))[2:end, :]),
    ["y", "yl"]
)
ols_ar = lm(@formula(y ~ yl), reg_data)

# Regress on factors (spread and level):
reg_data = DataFrame(
    Float64.(hcat(y, lag(y), df_factors[:, Not(:Date)] |> Matrix)[2:end, :]),
    ["y", "yl", "spread", "level"]
)
ols_factors = lm(@formula(y ~ yl + spread + level), reg_data)

# Regress on best subset of latent embeddings:
reg_data = DataFrame(
    Float64.(hcat(y, lag(y), A)[2:end, :]),
    ["y", "yl", ["a$i" for i in 1:size(A, 2)]...]
)
ols_best = lm(GLM.Term(:y) ~ sum(GLM.Term.(Symbol.(["yl", regressors...]))), reg_data)

reg_stats = regression_statistics = [
    Nobs => "Obs.",
    BIC,
    R2 => "R²",
]
labels = Dict(
    "y" => "GDP Growth",
    "yl" => "Lagged Growth",
    "spread" => "Spread",
    "level" => "Level",
    "a1" => "Embedding 1",
    "a2" => "Embedding 2",
    "a3" => "Embedding 3",
    "a4" => "Embedding 4",
    "a5" => "Embedding 5",
    "a6" => "Embedding 6",
)

# Results
regtable(
    ols_all_latent, ols_best_latent, ols_ar, ols_factors, ols_best;
    renderSettings=RegressionTables.htmlOutput(joinpath(RESULTS_DIR, "regression_full.html")),
    regression_statistics=reg_stats,
    labels=labels,
)
regtable(
    ols_all_latent, ols_best_latent, ols_ar, ols_factors, ols_best;
    renderSettings=RegressionTables.latexOutput(joinpath(RESULTS_DIR, "regression_full.tex")),
    regression_statistics=reg_stats,
    labels=labels,
)
regtable(
    ols_ar, ols_factors, ols_best;
    renderSettings=RegressionTables.htmlOutput(joinpath(RESULTS_DIR, "regression.html")),
    regression_statistics=reg_stats,
    labels=labels,
)
regtable(
    ols_ar, ols_factors, ols_best;
    renderSettings=RegressionTables.latexOutput(joinpath(RESULTS_DIR, "regression.tex")),
    regression_statistics=reg_stats,
    labels=labels,
)