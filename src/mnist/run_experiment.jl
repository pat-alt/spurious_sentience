using Pkg; Pkg.activate("src/mnist")

using CounterfactualExplanations.Data: load_mnist
using CounterfactualExplanations.Models: load_mnist_vae, load_mnist_mlp
using CSV
using DataFrames
using Flux
using GMT
using Images
using LinearAlgebra
using MLJBase
using MLJModels
using OneHotArrays

RESULTS_DIR = "results"
if !isdir(RESULTS_DIR)
    mkdir(RESULTS_DIR)
end
FIGURE_DIR = joinpath(RESULTS_DIR, "figures")

# Load MNIST data and pre-trained models:
data = load_mnist()
X = data.X
vae = load_mnist_vae()
mlp = load_mnist_mlp().model

# World Data (from https://github.com/wesg52/world-models/blob/main/data/entity_datasets/world_place.csv)
world_data = CSV.read("data/world_place.csv", DataFrame)

# FIFA World Rankings
# https://www.fifa.com/fifa-world-ranking/men?dateId=id14142
# Let's map the top 10 teams to the first 10 integers:
fifa_world_ranking = Dict(
    "Argentina" => 0,
    "France" => 1,
    "Brazil" => 2,
    "England" => 3,
    "Belgium" => 4,
    "Croatia" => 5,
    "Netherlands" => 6,
    "Portugal" => 7,
    "Italy" => 8,
    "Spain" => 9,
)

# Add FIFA World Rankings to World Data:
fifa_world_data = DataFrames.subset(world_data, :country => ByRow(x -> haskey(fifa_world_ranking, x))) |>
    x -> DataFrames.transform(x, :country => ByRow(x -> fifa_world_ranking[x]) => :y) |>
    x -> DataFrames.select(x, :y, Not(:y, :country))

# Tokenizer for FIFA World Data ====================
# Goal: need a tokenizer that can map from the entities to the latent space of the VAE.
# Continuous feature encoding:
X = fifa_world_data[:,Not(:y)]
model = (X -> coerce(
        X,
        :entity_type => Multiclass,
)) |> 
    MLJModels.FillImputer() |>
    MLJModels.ContinuousEncoder() |> 
    MLJModels.Standardizer() 
mach = machine(model, X)
MLJBase.fit!(mach)
Xtrain = MLJBase.transform(mach, X) |> 
    MLJBase.matrix |> 
    permutedims |>
    x -> Float32.(x)
# One-hot encoding:
y = fifa_world_data.y
ytrain = OneHotArrays.onehotbatch(y, 0:9)
# Dataloader:
dl = Flux.DataLoader((Xtrain, ytrain), batchsize=32, shuffle=true)
# Tokenizer:
latent = 64
activation = relu
function head(Xhat)
    return mlp(Xhat)
end
# A small MLP as our backbone, then a linear layer to map to the latent space:
tokenizer = Chain(
    Dense(size(Xtrain, 1) => latent, activation),
    Dense(latent => latent, activation),
    Dense(latent => vae.params.latent_dim),
)
# The decoder of our VAE:
reconstructor = Chain(
    vae.decoder,
    x -> clamp.(x, -1, 1),
)
# A pre-trained MLP as our head to predict labels for the generated tokens:
model = Chain(
    tokenizer,
    reconstructor,
    head,
)
loss(ŷ,y) = Flux.logitcrossentropy(ŷ, y)
opt_state = Flux.setup(Adam(), model)
# Train:
epochs = 10
for epoch in 1:epochs
    Flux.train!(model, dl, opt_state) do m, x, y
        loss(m(x), y)
    end
end

# Linear Probes ====================
λ = 0.1
A = tokenizer(Xtrain) |> permutedims
Y = fifa_world_data[:, [:longitude, :latitude]] |> matrix
W = (A'A + UniformScaling(λ)) \ A'Y

# Fitted values:
labels = OneHotArrays.onecold(ytrain)
Ŷ = A * W
coast(;
    region=:global,
    proj = :Mollweide,
    shore=(level=1, pen=(0.5, :black)),
    figsize=12,
    show=false,
)
GMT.scatter!(
    Ŷ[:, 1],
    Ŷ[:, 2];
    color=:rainbow,
    zcolor=labels,
    show = false,
    ms = 0.05,
    savefig = joinpath(FIGURE_DIR, "map.png"),
)