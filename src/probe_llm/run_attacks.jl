if COMPUTE_EMBEDDINGS
    tfm = load_model(; load_head=false)
end
n_pc = 128
layer = 24
ispath(joinpath(save_dir, "attacks")) || mkpath(joinpath(save_dir, "attacks"))
attack_sentence_dir = "results/attacks/sentences"
ispath(attack_sentence_dir) || mkpath(attack_sentence_dir)
prefx = USE_ALL_SENTENCES ? "all_" : ""

high_inf_text = readlines(joinpath(attack_sentence_dir, "$(prefx)high_inf.txt"))[1]
high_inf_query = split(high_inf_text, ";") |>
                 x -> String.(x)

hawk_text = readlines(joinpath(attack_sentence_dir, "$(prefx)hawk.txt"))[1]
hawk_query = split(hawk_text, ";") |>
             x -> String.(x)

low_inf_text = readlines(joinpath(attack_sentence_dir, "$(prefx)low_inf.txt"))[1]
low_inf_query = split(low_inf_text, ";") |>
                x -> String.(x)

dove_text = readlines(joinpath(attack_sentence_dir, "$(prefx)dove.txt"))[1]
dove_query = split(dove_text, ";") |>
             x -> String.(x)

queries = zip([high_inf_query, hawk_query, low_inf_query, dove_query], ["high_inf", "hawk", "low_inf", "dove"])

# Embed the queries:
queries_embedded = []
if COMPUTE_EMBEDDINGS
    Threads.@threads for (q, cat) in collect(queries)
        println("Embedding queries for $cat on thread $(Threads.threadid())")
        embedding = []
        for i in collect(eachindex(q))
            push!(embedding, embed_text(tfm, [q[i]]))
            println("$i/$(length(q)) done on thread $(Threads.threadid())")
        end
        embedding = vcat(embedding...)
        push!(queries_embedded, (q, embedding, cat))
    end
    for (query, embedding, name) in queries_embedded
        CSV.write(joinpath(save_dir, "attacks", "$(prefx)attack_$name.csv"), DataFrame(embedding, :auto))
    end
else
    for (query, name) in queries
        embedding = CSV.read(joinpath(save_dir, "attacks", "$(prefx)attack_$name.csv"), DataFrame) |> Matrix
        push!(queries_embedded, (query, embedding, name))
    end
end

# Predict from the probes:
indicators = [
    ("CPI", missing),
    ("PPI", missing),
    ("UST", "1 Mo"),
    ("UST", "1 Yr"),
    ("UST", "10 Yr"),
]

predictions = []
for (ind, mat) in indicators
    ind_mat = ismissing(mat) ? ind : "$ind ($mat)"
    println("Running attacks for $ind_mat")
    # Get the data and models:
    agg_data, probes, probe_data = run_models(
        all_data;
        n_pc=n_pc,
        return_meta=true,
        layer=layer,
        indicator=ind,
        maturity=mat,
    )
    _mod, X, Σ, V = get_best_probe(agg_data, probes, probe_data)
    d = size(X, 2)
    df_pred = []
    mom_val = median([mean(_mod(randn(1000, d))) for i in 1:10000])
    for (query, embedding, name) in queries_embedded
        df = DataFrame(
            query=query,
            level=embedding_to_probe(
                _mod, embedding;
                n_pc=n_pc, Σ=Σ, V=V
            ) .- mom_val,
            sentence=1:length(query),
            cat=name,
            dir=name ∈ ["high_inf", "hawk"] ? "Inflation" : "Deflation",
            topic=name ∈ ["high_inf", "low_inf"] ? "Prices" : "Birds",
            indicator=ind_mat
        )
        push!(df_pred, df)
    end
    df_pred = vcat(df_pred...)
    push!(predictions, df_pred)
end
predictions = vcat(predictions...)

plt_inflation = plot_attack(filter(x -> x.indicator == "CPI", predictions))
plt_all = plot_attack(predictions)

save(joinpath(save_dir, "figures", "$(prefx)attack_inflation.png"), plt_inflation, px_per_unit=3)
save(joinpath(save_dir, "figures", "$(prefx)attack_all_measures.png"), plt_all, px_per_unit=3)