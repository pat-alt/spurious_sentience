using LinearAlgebra
using Statistics

abstract type Model end

function (mod::Model)(X)
    return predict(mod, X)
end

function predict(mod::Model, X)
    if mod.intercept && size(X, 2) == size(mod.β, 1) - 1
        X = hcat(ones(size(X, 1)), X)
    end
    return X * mod.β
end

ssr(mod::Model, X, y) = sum((y .- predict(mod, X)) .^ 2)

function mse(mod::Model, X, y)
    ŷ = predict(mod, X)
    return mean((y .- ŷ) .^ 2)
end

rmse(mod::Model, X, y) = sqrt(mse(mod, X, y))

struct Probe <: Model
    β::Vector{Float64}
    intercept::Bool
    λ::Float64
end

function probe(X, y; λ::Real=0.1, intercept::Bool=true)
    if intercept
        X = hcat(ones(size(X, 1)), X)
    end
    β = (X'X + UniformScaling(λ))\(X'y)
    return Probe(β, intercept, λ)
end

lag(X::Vector, l=1) = [zeros(l) ; X[1:end-l]]

struct AutoRegression <: Model
    β::Vector{Float64}
    intercept::Bool
    l::Int
end

function prepare_ar(y; l::Int=1, intercept::Bool=true)
    X = hcat([lag(y, i) for i in 1:l]...)
    if intercept
        X = hcat(ones(size(X, 1)), X)
    end
    return X
end

function ar(y; l::Int=1, intercept::Bool=true)
    X = prepare_ar(y; l=l, intercept=intercept)
    β = (X'X)\(X'y)
    return AutoRegression(β, intercept, l), X
end

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

bic(ssr, n, lags) = n * log.(ssr ./ n) .+ log.(n) .* lags

aic(ssr, n, lags) = n * log.(ssr ./ n) .+ 2 .* lags

function get_clf_activations(clf, X)
    A = clf.layer.layers[1](X).hidden_state |>
        x -> clf.layer.layers[2](x).hidden_state
    return A
end