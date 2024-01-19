# Score the results:
DataFrame(
    indicator=indicator,
    model=["Probe", "AR($p)"],
    rmse=[rmse(mod, X, y), rmse(mod_bl, _X[:, 2:end], _y)],
    mse=[mse(mod, X, y), mse(mod_bl, _X[:, 2:end], _y)],
    cor=[cor(y, yhat), cor(_y, y_bl)]
)