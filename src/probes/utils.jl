using LinearAlgebra
using Statistics

abstract type Model end

"""
    (mod::Model)(X)

Predict the output of a model `mod` on the input `X`.
"""
function (mod::Model)(X)
    return predict(mod, X)
end

"""
    predict(mod::Model, X)

Predict the output of a model `mod` on the input `X`.
"""
function predict(mod::Model, X)
    if mod.intercept && size(X, 2) == size(mod.β, 1) - 1
        X = hcat(ones(size(X, 1)), X)
    end
    return X * mod.β
end

"""
    ssr(mod::Model, X, y)

Compute the sum of squared residuals of a model `mod` on the input `X` and output `y`.
"""
ssr(mod::Model, X, y) = ssr(y, predict(mod, X))

"""
    ssr(y, ŷ)

Compute the sum of squared residuals of a model `mod` on the output `y` and predicted output `ŷ`.
"""
ssr(y, ŷ) = sum((y .- ŷ) .^ 2)

"""
    mse(mod::Model, X, y)

Compute the mean squared error of a model `mod` on the input `X` and output `y`.
"""
mse(mod::Model, X, y; weights::Union{Nothing,AbstractArray}=nothing) = mse(y, predict(mod, X); weights=weights)

"""
    mse(y, ŷ)       

Compute the mean squared error of a model `mod` on the output `y` and predicted output `ŷ`.
"""
function mse(y, ŷ; weights::Union{Nothing,AbstractArray}=nothing)
    if isnothing(weights)
        return mean((y .- ŷ) .^ 2)
    else
        return mean((y .- ŷ) .^ 2, Weights(weights))
    end
end

"""
    rmse(mod::Model, X, y)

Compute the root mean squared error of a model `mod` on the input `X` and output `y`.
"""
rmse(mod::Model, X, y; weights::Union{Nothing,AbstractArray}=nothing) = rmse(y, predict(mod, X); weights=weights)

"""
    rmse(y, ŷ)

Compute the root mean squared error of a model `mod` on the output `y` and predicted output `ŷ`.
"""
rmse(y, ŷ; weights::Union{Nothing,AbstractArray}=nothing) = sqrt(mse(y, ŷ; weights=weights))

struct Probe <: Model
    β::Vector{Float64}
    intercept::Bool
    λ::Float64
end

"""
    probe(X, y; λ::Real=0.1, intercept::Bool=true)

Fit a probe to the input `X` and output `y`.
"""
function probe(X, y; λ::Real=0.1, intercept::Bool=true)
    if intercept
        X = hcat(ones(size(X, 1)), X)
    end
    β = (X'X + UniformScaling(λ))\(X'y)
    return Probe(β, intercept, λ)
end

"""
    lag(X::Vector, l=1)

Lag a vector `X` by `l` periods.
"""
lag(X::Vector, l=1) = [zeros(l) ; X[1:end-l]]

struct AutoRegression <: Model
    β::Vector{Float64}
    intercept::Bool
    l::Int
end

"""
    prepare_ar(y; l::Int=1, intercept::Bool=true)

Prepare the input matrix for an autoregressive model.
"""
function prepare_ar(y; l::Int=1, intercept::Bool=true)
    X = hcat([lag(y, i) for i in 1:l]...)
    if intercept
        X = hcat(ones(size(X, 1)), X)
    end
    return X
end

"""
    ar(y; l::Int=1, intercept::Bool=true)

Fit an autoregressive model to the output `y`.
"""
function ar(y; l::Int=1, intercept::Bool=true)
    X = prepare_ar(y; l=l, intercept=intercept)
    β = (X'X)\(X'y)
    return AutoRegression(β, intercept, l), X
end

"""
    lag_select(y; criterium::Function=aic, max_lag::Int=10, return_scores::Bool=false)

Select the optimal lag for an autoregressive model. Depending on the value of `return_scores`, either return the optimal lag or a tuple of the optimal lag and the scores for all lags. The `criterium` function should take the sum of squared residuals, the number of observations, and the number of lags as arguments and return a vector of scores for each lag.
"""
function lag_select(
    y; 
    criterium::Function=aic, 
    max_lag::Int=10, 
    return_scores::Bool=false,
    kwrgs...
)
    n = size(y, 1)
    lags = 1:max_lag
    models = [ar(y; l=l, kwrgs...) for l in lags]
    ssrs = [ssr(mod, X, y) for (mod,X) in models]
    scores = criterium(ssrs, n, lags)
    p = lags[argmin(scores)]
    return_scores || return p
    return p, scores
end

"""
    bic(ssr, n, lags)

Compute the Bayesian information criterion for a set of models.
"""
bic(ssr, n, lags) = n * log.(ssr ./ n) .+ log.(n) .* lags

"""
    aic(ssr, n, lags)

Compute the Akaike information criterion for a set of models.
"""
aic(ssr, n, lags) = n * log.(ssr ./ n) .+ 2 .* lags

"""
    get_clf_activations(clf, X)

Get the activations of the penultimate layer of a classifier `clf` on the input `X` where `X` is a matrix of word embeddings (in other words the final-layer activations of a language model.
"""
function get_clf_activations(clf, X)
    A = clf.layer.layers[1](X).hidden_state |>
        x -> clf.layer.layers[2](x).hidden_state
    return A
end

"""
    prepare_mkt_data(all_data, indicator)

Prepare the inflation data for a probe. This involves:

- Lagging the data by one period.
- Taking the log difference.
- Selecting the relevant columns.
"""
function prepare_mkt_data(
    all_data::DataFrame,
    indicator::AbstractString="PPI",
    maturity::Nothing=nothing,
)
    data = subset(all_data, :indicator => x -> x.==indicator)
    transform!(data, :date => ByRow(x -> Dates.yearmonth(x)) => :ym)
    data = groupby(data, :ym) |>
        x -> select(x, [:ym, :value]) |>
        unique |>
        x -> transform(x, :value => lag => :value_lag) |>
        x -> select(x, Not(:value)) |>
        x -> innerjoin(x, data, on=:ym) |>
        x -> transform(x, [:value, :value_lag] => ByRow((y,yl) -> log(y)-log(yl)) => :growth) 
    replace!(data.growth, Inf => 0.0)
    select!(data, Not([:value]))
    rename!(data, :growth => :value)
    
    return data
end

"""
    post_process_mkt_data(data::DataFrame)

Post-process the market data for a probe. This involves:

- Selecting the relevant columns.
- Sorting the data.
"""
function post_process_mkt_data(data::DataFrame)
    select!(data, [:date, :ym, :sentence_id, :value, :event_type, :speaker])
    sort!(data, [:sentence_id, :date, :ym])
    return data
end

"""
    prepare_mkt_data(all_data, maturity)

Prepare the yield data for a probe. This involves:

- Selecting the relevant columns.
"""
function prepare_mkt_data(
    all_data::DataFrame,
    indicator::AbstractString="UST", 
    maturity::AbstractString="1 Mo",
)
    data = subset(all_data, :indicator => x -> x.==indicator, :maturity =>  x -> x.==maturity, skipmissing=true)
    transform!(data, :date => ByRow(x -> Dates.yearmonth(x)) => :ym)
    select!(data, [:date, :ym, :sentence_id, :value])
    sort!(data, [:sentence_id,:ym])
    return data
end

function agg_probe_results(data::DataFrame)
    agg_data = groupby(data, :ym) |>
        x -> combine(x, :value .=> mean; renamecols=false)
    return agg_data
end