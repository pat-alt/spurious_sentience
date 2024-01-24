dl = Flux.MLUtils.DataLoader((permutedims(X), permutedims(y)), batchsize=24, shuffle=true)
input_dim = size(X, 2)
n_pc = 6
n_hidden = 32
epochs = 1000
activation = tanh_fast
encoder = Flux.Chain(
    Dense(input_dim => n_hidden, activation),
    Dense(n_hidden => n_pc, activation),
)
decoder = Flux.Chain(
    Dense(n_pc => n_hidden, activation),
    Dense(n_hidden => input_dim, activation),
)
model = Flux.Chain(
    encoder.layers...,
    decoder.layers...,
    Dense(input_dim, 1),
)
plt = plot(model, rand(input_dim))
display(plt)