# Just plot the time series:
include("plot_ts.jl")

# Build the model architecture and plot it:
include("model.jl")

# Train the model:
include("train_model.jl")

# Prepare the linear probes:
include("prepare_probe_data.jl")

# Run the linear probes and plot the results:
include("run_probe.jl")

# Run OLS regressions and generate tables:
include("regression.jl")