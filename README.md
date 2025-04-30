# Spurious Sparks

This repo contains all code used for our ICML 2024 paper: [Position: Stop Making Unscientific AGI Performance Claims](https://proceedings.mlr.press/v235/altmeyer24a.html) 

[![DOI](https://zenodo.org/badge/744927925.svg)](https://doi.org/10.5281/zenodo.15309219)

## Code

All code used for our experiments is contained in the [src](src) folder. Dependencies are defined in TOML files. 

### Dependencies

We created the [TrillionDollarWords.jl](https://github.com/pat-alt/TrillionDollarWords.jl) package as a reusable research software package used for the some of the experiments in this repo.

### Simple Examples

To set up the environment for the simple examples (PCA, autoencoder), run the following:

```shell
julia --project=src/simple_examples
```

This will start an interactive Julia session and activate the relevant environment. Then simply run the following:

```julia
using Pkg; Pkg.instantiate()
```

After this, you can exit the Julia session.

#### Example: PCA

The PCA experiment can be run as follows:

```shell
julia --project=src/simple_examples src/simple_examples/pca/run_experiment.jl
```

#### Example: Autoencoder

The autoencoder experiment can be run as follows:

```shell
julia --project=src/simple_examples src/simple_examples/autoencoder/run_experiment.jl
```

### LLM Example

To set up the environment for the LLM experiment, run the following:

```shell
julia --project 
```

This will start an interactive Julia session and activate the relevant environment. Then simply run the following:

```julia
using Pkg; Pkg.instantiate()
```

After this, you can exit the Julia session.




