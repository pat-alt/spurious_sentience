using LinearAlgebra
using Statistics

abstract type Model end

function (mod::Model)(X)
    return predict(mod, X)
end

function predict(mod::Model, X)
    if mod.intercept
        X = hcat(ones(size(X, 1)), X)
    end
    return X * mod.β
end

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

function ar(y; l::Int=1, intercept::Bool=true)
    X = hcat([lag(y, i) for i in 1:l]...)
    if intercept
        X = hcat(ones(size(X, 1)), X)
    end
    β = (X'X)\(X'y)
    return AutoRegression(β, intercept, l), X
end