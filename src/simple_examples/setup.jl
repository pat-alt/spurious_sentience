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

df = CSV.read("data/ust_yields.csv", DataFrame) |>
     x -> @pivot_longer(x, -Date) |>
          x -> @mutate(x, variable = to_year(variable)) |>
               x -> @mutate(x, year = Dates.year(Date)) |>
                    x -> @mutate(x, quarter = Dates.quarter(Date)) |>
                         x -> @mutate(x, Date = Dates.format(Date, "yyyy-mm-dd")) |>
                              x -> @arrange(x, Date) |>
                                   x -> @fill_missing(x, "down")
ylims = extrema(skipmissing(df.value))

# Peak-crisis:
onset_date = "2007-02-27"
plt_df = df[df.Date.==onset_date, :]
plt = plot(
    plt_df.variable, plt_df.value;
    label="", color=:blue,
    xlabel="Maturity (years)", ylabel="Yield (%)",
)
scatter!(
    plt_df.variable, plt_df.value;
    label="", color=:blue, alpha=0.5,
    ylims=(0, 6)
)
display(plt)

# Post-crisis:
aftermath_date = "2009-04-20"
plt_df = df[df.Date.==aftermath_date, :]
plt = plot(
    plt_df.variable, plt_df.value;
    label="", color=:blue,
    xlabel="Maturity (years)", ylabel="Yield (%)",
)
scatter!(
    plt_df.variable, plt_df.value;
    label="", color=:blue, alpha=0.5,
    ylims=(0, 6)
)
display(plt)