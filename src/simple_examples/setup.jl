# Set up:
ENV_DIR = "src/simple_examples"
using Pkg;
Pkg.activate(ENV_DIR);

# Packages:
using CSV
using ChainPlots
using DataFrames
using Dates
using Flux
using GLM
using LinearAlgebra
using Plots
using Plots.PlotMeasures
using Printf
using TidierData
using Random
using Serialization
using RegressionTables
Random.seed!(2024)

# Utility functions:
include("utils.jl")

RESULTS_DIR = "results"
if !isdir(RESULTS_DIR)
    mkdir(RESULTS_DIR)
end
FIGURE_DIR = joinpath(RESULTS_DIR, "figures")