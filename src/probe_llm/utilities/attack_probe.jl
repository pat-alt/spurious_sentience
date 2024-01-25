"""
    get_best_probe(
        agg_data, probes, probe_data;
        agg_vars=[:indicator, :maturity, :layer, :split, :fold, :n_pc, :variable, :model],
        eval_var="rmse"
    )

Get the best probe based on the evaluation metric `eval_var`.
"""
function get_best_probe(
    agg_data, probes, probe_data;
    agg_vars=[:indicator, :maturity, :layer, :split, :fold, :n_pc, :variable, :model],
    eval_var="rmse"
)
    best_res = evaluate(agg_data, agg_vars=agg_vars) |>
        df -> subset(
            df, 
            :split => x -> x .== "test",
            :variable => x -> x .== String(eval_var),
            :model => x -> x .== "y_probe"
        ) |>
        df -> argmin(df.value) 
    mod = probes[best_res]
    X, Σ, V = probe_data[best_res]
    return mod, X, Σ, V
end

"""
    encode_pca(X, Σ, V)

Encode a matrix `X` using the principal components `Σ` and `V` from a previous PCA.
"""
encode_pca(X, Σ, V) = X * inv(diagm(Σ) * V')

"""
    text_to_probe(tfm, probe, query)

Run a probe on a query. First, the query is transformed using the transformer `tfm`. Then, the PCA is applied to the query. Finally, the probe is run on the PCA-encoded query.
"""
function text_to_probe(
    tfm::BaselineModel, mod::Probe, query::Vector{<:AbstractString}; 
    n_pc=n_pc, Σ=Σ, V=V
)
    # Get the word embeddings:
    X = embed_text(tfm, query)
    return embedding_to_probe(mod, X; n_pc=n_pc, Σ=Σ, V=V)
end

"""
    embedd_text(tfm::BaselineModel, query::Vector{<:AbstractString})

Embed a query using a transformer `tfm`.
"""
function embed_text(tfm::BaselineModel, query::Vector{<:AbstractString})
    # Get the word embeddings:
    X = tfm(query) |>
        x -> Transformers.HuggingFace.FirstTokenPooler()(x.hidden_state) |>
        x -> Matrix(x')
    return X
end

"""
    embedding_to_probe(mod::Probe, X::Matrix{<:Real}; n_pc=n_pc)

Run a probe on a matrix of word embeddings `X`. First, the PCA is applied to the query. Finally, the probe is run on the PCA-encoded query.
"""
function embedding_to_probe(
    mod::Probe, X::Matrix{<:Real}; 
    n_pc=n_pc, Σ=Σ, V=V
)
    # Encode using the PCA:
    X = encode_pca(X, Σ, V) |>
        x -> x[:, 1:n_pc]
    # Run the probe:
    yhat = mod(X)
    return yhat
end





