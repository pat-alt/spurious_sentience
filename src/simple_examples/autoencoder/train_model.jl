loss(yhat, y) = Flux.mse(yhat, y)
opt = Adam()
opt_state = Flux.setup(opt, model)
for epoch in 1:epochs
    Flux.train!(model, dl, opt_state) do m, x, y
        loss(m(x), y)
    end
end