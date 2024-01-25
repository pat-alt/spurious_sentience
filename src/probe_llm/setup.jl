using AlgebraOfGraphics
using CairoMakie
using CSV
using DataFrames
using Dates
import Plots
using Statistics
using StatsBase: cor, Weights
using Transformers
using TrillionDollarWords

# Utility functions:
include("utilities/core.jl")
include("utilities/models.jl")
include("utilities/evaluation.jl")
include("utilities/plotting.jl")
include("utilities/attack_probe.jl")

# All data:
all_data = load_all_data()

# Directories:
save_dir = "results"
interim_dir = joinpath(save_dir, "interim")
ispath(interim_dir) || mkdir(interim_dir)
all_saved = sort(parse.(Int, filter.(isdigit, readdir(interim_dir))))
last_saved = length(all_saved) > 0 ? maximum(all_saved) : 0