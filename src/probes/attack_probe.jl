n_pc = 128
layer = 24
agg_data, probes, probe_data = run_models(all_data; n_pc=n_pc, return_meta=true, layer=layer)
best_res = evaluate(agg_data, agg_vars=[:indicator, :maturity, :layer, :split, :fold, :n_pc, :variable, :model]) |>
    df -> subset(
        df, 
        :split => x -> x .== "test",
        :variable => x -> x .== "rmse",
        :model => x -> x .== "y_probe"
    ) |>
    df -> argmin(df.value) 
mod = probes[best_res]
X, Σ, V = probe_data[best_res]

"""
    encode_pca(X, Σ, V)

Encode a matrix `X` using the principal components `Σ` and `V` from a previous PCA.
"""
encode_pca(X, Σ=Σ, V=V) = X * inv(diagm(Σ) * V')

tfm = load_model(; load_head=false)

"""
    text_to_probe(tfm, probe, query)

Run a probe on a query. First, the query is transformed using the transformer `tfm`. Then, the PCA is applied to the query. Finally, the probe is run on the PCA-encoded query.
"""
function text_to_probe(tfm::BaselineModel, mod::Probe, query::Vector{<:AbstractString})
    # Get the word embeddings:
    X = tfm(query) |>
        x -> Transformers.HuggingFace.FirstTokenPooler()(x.hidden_state)
    # Encode using the PCA:
    X = encode_pca(X')[:, 1:n_pc]
    # Run the probe:
    yhat = mod(X)
    return yhat
end

high_inf_text = "Consumer prices are at all-time highs.;Inflation is expected to rise further.;The Fed is expected to raise interest rates to curb inflation.;Excessively loose monetary policy is the cause of the inflation.;It is essential to bring inflation back to target to avoid drifting into hyperinflation territory."
high_inf_query = split(high_inf_text, ";") |> 
    x -> String.(x)

hawk_text = "The number of hawks is at all-time highs.;Their levels are expected to rise further.;The Federal Association of Birds is expected to raise extremely high barriers to curb hawk migration.;Excessively loose immigration policy for hawks is the likely cause of their numbers being so far above target.;It is essential to bring the number of hawks back to target to avoid drifting into hyper-hawk territory."
hawk_query = split(hawk_text, ";") |>
    x -> String.(x)

low_inf_text = "Consumer prices are at all-time lows.;Inflation is expected to fall further.;The Fed is expected to lower interest rates to boost inflation.;Excessively tight monetary policy is the cause of deflationary pressures.;It is essential to bring inflation back to target to avoid drifting into deflation territory."
low_inf_query = split(low_inf_text, ";") |>
    x -> String.(x)

dove_text = "The number of doves is at all-time lows.;Their levels are expected to fall further.;The Federal Association of Birds is expected to lower barriers of entry to doves.;Excessively tight immigration policy for doves is the likely cause of their numbers being so far below target.;It is essential to bring the numbers of doves back to target to avoid drifting into dovelation territory."

dove_query = split(dove_text, ";") |>
    x -> String.(x)

queries = zip([high_inf_query, hawk_query, low_inf_query, dove_query], ["high_inf", "hawk", "low_inf", "dove"])

df_pred = []
for (query,name) in queries
    df = DataFrame(
        query = query,
        level = cumsum(text_to_probe(tfm, mod, query)),
        sentence = 1:length(query),
        cat = name,
        dir = name ∈ ["high_inf", "hawk"] ? "Up" : "Down",
        topic = name ∈ ["high_inf", "low_inf"] ? "Prices" : "Birds"
    )
    push!(df_pred, df)
end
df_pred = vcat(df_pred...)

plt = data(df_pred) * mapping(
    :sentence => "Sentence", 
    :level => "CPI Level",
    color=:dir => "Direction",
    linestyle=:topic => "Topic",
)
layer = visual(Lines)
plt = draw(
    layer * plt,
    axis=(width=225, height=225)
)
save(joinpath(save_dir, "figures", "attack.png"), plt, px_per_unit=3)



