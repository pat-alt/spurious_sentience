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

include("utils.jl")
include("run_models.jl")
include("evaluation.jl")
include("plotting.jl")
include("attack_probe.jl")

# All data:
all_data = load_all_data()

# Setup:
save_dir = "results"
interim_dir = joinpath(save_dir, "interim")
ispath(interim_dir) || mkdir(interim_dir)
all_saved = sort(parse.(Int, filter.(isdigit, readdir(interim_dir))))
last_saved = length(all_saved) > 0 ? maximum(all_saved) : 0

# Parameter grid:
n_pcs = [nothing, 128]
use_head = [false, true]
indicator = ["PPI", "CPI", "UST"]
maturity = ["1 Mo", "1 Yr", "10 Yr"]
layer = 1:24
grids = []
for ind in indicator
    for (i,_head) in enumerate(use_head)
        _mat = ind != "UST" ? [missing] : maturity
        _layer = _head ? [25] : layer
        grid = Base.Iterators.product(_head, _mat, _layer, n_pcs) |> 
            collect |>
            x -> DataFrame(vec(x), [:use_head, :maturity, :layer, :n_pc])
        grid.indicator .= ind
        push!(grids, grid)
    end
end
grid = vcat(grids...)

# Run the models:
results = []
for (i, row) in enumerate(eachrow(grid))
    if i <= last_saved
        _results = CSV.read(joinpath(interim_dir, "results_$i.csv"), DataFrame)
    else
        println("Running models for experiment $i of $(nrow(grid))")
        _results = run_models(
            all_data; 
            indicator=row.indicator, 
            maturity=row.maturity, 
            layer=row.layer, 
            use_head=row.use_head,
            n_pc=row.n_pc,
        )
        CSV.write(joinpath(interim_dir, "results_$i.csv"), _results)
    end
    push!(results, _results)
end
results = vcat(results...)

# Save the results:
CSV.write(
    joinpath(save_dir, "results.csv"), results, 
    append=ifelse(isfile(joinpath(save_dir, "results.csv")), true, false)
)

# Evaluate the results:
results = CSV.read(joinpath(save_dir, "results.csv"), DataFrame)
gdf = groupby(results, [:indicator, :maturity, :layer]) 
df_evals = vcat([evaluate(DataFrame(g)) for g in gdf]...)
CSV.write(joinpath(save_dir, "evaluations.csv"), df_evals)

# Plot the results:
ispath(joinpath(save_dir, "figures")) || mkdir(joinpath(save_dir, "figures"))
df_evals = CSV.read(joinpath(save_dir, "evaluations.csv"), DataFrame)
gdf = groupby(df_evals, [:indicator, :maturity, :n_pc]) 
axis = (width=225, height=225)
for g in gdf
    g = DataFrame(g)
    i = g.indicator[1]
    m = g.maturity[1] |> x -> ismissing(x) ? "" : " ($x)"
    n_pc = g.n_pc[1] |> x -> ismissing(x) ? "" : " (n_pc=$x)"
    title = "$i$m$n_pc"
    plt = plot_measures(g, axis=axis)
    save(joinpath(save_dir, "figures", "measures_$title.png"), plt, px_per_unit=3) 
end

# Attack probe:
n_pc = 128
layer = 24
tfm = load_model(; load_head=false)

high_inf_text = "Consumer prices are at all-time highs.;Inflation is expected to rise further.;The Fed is expected to raise interest rates to curb inflation.;Excessively loose monetary policy is the cause of the inflation.;It is essential to bring inflation back to target to avoid drifting into hyperinflation territory."
high_inf_query = split(high_inf_text, ";") |>
    x -> String.(x)

hawk_text = "The number of hawks is at all-time highs.;Their levels are expected to rise further.;The Federal Association of Birds is expected to raise barriers of entry for hawks to bring their numbers back down to the target level.;Excessively loose migration policy for hawks is the likely cause of their numbers being so far above target.;It is essential to bring the number of hawks back to target to avoid drifting into hyper-hawk territory."
hawk_query = split(hawk_text, ";") |>
    x -> String.(x)

hawk_text_long = "The number of hawks is at all-time highs.;Their levels are expected to rise further.;The Federal Association of Birds is expected to raise barriers of entry for hawks to bring their numbers back down to the target level.;Excessively loose migration policy for hawks is the likely cause of their numbers being so far above target.;It is essential to bring the number of hawks back to target to avoid drifting into hyper-hawk territory.;Inflationary pressures within the hawk demographic are reaching alarming levels, prompting calls for decisive action from avian authorities.;Forecasts indicate a steady upward trajectory in hawk levels, raising worries about the economic implications of soaring avian prices.;The Avian Regulatory Authority is poised to implement stringent measures, aiming to rein in hawk numbers and restore equilibrium to the avian market.;Loose policies on hawk migration are cited as the primary factor behind the unexpected surge in their population, fueling concerns of inflationary consequences.;Preventing the avian ecosystem from entering hyper-hawk territory is paramount and requires immediate attention to bring hawk numbers back in line with targets.;In response to inflationary signals, the Avian Central Bank is considering measures to stabilize hawk quantities and prevent a broader economic downturn.;Economic analysts are grappling with the sudden inflation of hawk numbers, advocating for proactive strategies to mitigate potential avian price hikes.;The Avian Reserve is on high alert as hawk figures threaten to breach critical thresholds, necessitating swift measures to avoid an avian bubble.;Stringent policies to regulate hawk numbers aim to address fears of an overheated avian market and potential inflationary consequences.;Experts underscore the urgency of controlling hawk population growth to avert a full-blown avian inflation crisis.;The surge in hawk numbers is creating inflationary ripples throughout the avian economy, prompting authorities to consider interventions for stability.;Avian policymakers are closely monitoring hawk metrics to identify and address potential triggers for inflation within the avian market.;A sharp uptick in hawk numbers has raised concerns about an impending avian inflation crisis, prompting calls for immediate regulatory measures.;The Avian Economic Council is deliberating on strategies to mitigate the inflationary impact of rising hawk levels and restore market confidence.;Hawk-induced inflationary pressures are prompting avian regulators to explore targeted measures to cool down the market and avoid widespread economic fallout.;The Avian Reserve Board is closely scrutinizing hawk statistics, signaling potential interventions to manage their population dynamics and prevent inflationary spikes.;Economic indicators suggest a looming avian inflation crisis, necessitating proactive steps to control hawk numbers and stabilize the market.;The prospect of a hawk-induced inflationary spiral is prompting calls for decisive measures to bring their population back within the target range.;Avian authorities are considering hawk control policies to address concerns of an overheated market and potential inflationary pressures on avian resources.;In response to inflationary trends, the Avian Central Bank is contemplating hawk management strategies to ensure the stability of the avian economy.;Concerns over rising hawk numbers are prompting discussions on implementing policies to rein in their population growth and prevent an avian bubble.;The Avian Economic Council is alert to potential hawk-induced inflation, advocating for preemptive measures to control their numbers and maintain market stability.;A sudden surge in hawk figures is fueling fears of an avian inflation crisis, urging policymakers to take swift action to prevent economic imbalances.;Rising hawk levels are causing inflationary tremors in the avian market, prompting authorities to consider targeted interventions to stabilize the economy.;The Avian Reserve Board is closely monitoring hawk statistics, signaling potential measures to manage their population dynamics and prevent inflationary spikes.;Economic indicators point to a looming avian inflation crisis, prompting calls for decisive measures to control hawk numbers and stabilize the market.;The prospect of a hawk-induced inflationary spiral is prompting avian authorities to take preemptive steps to bring their population back within the target range.;Concerns over rising hawk numbers are fueling discussions on implementing policies to rein in their population growth and prevent an avian bubble.;The Avian Economic Council is on high alert, advocating for preemptive measures to control hawk numbers and maintain market stability in the face of potential inflationary pressures.;A sudden surge in hawk figures is prompting fears of an avian inflation crisis, urging policymakers to take swift action to prevent economic imbalances.;Rising hawk levels are causing inflationary tremors in the avian market, prompting authorities to consider targeted interventions to stabilize the economy.;The Avian Reserve Board is closely monitoring hawk statistics, signaling potential measures to manage their population dynamics and prevent inflationary spikes.;Economic indicators point to a looming avian inflation crisis, prompting calls for decisive measures to control hawk numbers and stabilize the market.;The prospect of a hawk-induced inflationary spiral is prompting avian authorities to take preemptive steps to bring their population back within the target range.;Concerns over rising hawk numbers are fueling discussions on implementing policies to rein in their population growth and prevent an avian bubble."
hawk_query_long = split(hawk_text_long, ";") |>
    x -> String.(x)

low_inf_text = "Consumer prices are at all-time lows.;Inflation is expected to fall further.;The Fed is expected to lower interest rates to boost inflation.;Excessively tight monetary policy is the cause of deflationary pressures.;It is essential to bring inflation back to target to avoid drifting into deflation territory."
low_inf_query = split(low_inf_text, ";") |>
    x -> String.(x)

dove_text = "The number of doves is at all-time lows.;Their levels are expected to fall further.;The Federal Association of Birds is expected to lower barriers of entry for doves to bring their numbers back up to the target level.;Excessively tight migration policy for doves is the likely cause of their numbers being so far below target.;It is essential to bring the numbers of doves back to target to avoid drifting into dovelation territory.;The inflationary pressures on dove populations are at all-time lows.;Their prices are expected to fall further.;The Central Avian Reserve is expected to lower barriers of entry for doves to bring their numbers back up to the target level.;Excessively tight migration policy for doves is the likely cause of their numbers being so far below target.;It is essential to bring the numbers of doves back to target to avoid drifting into dovelation territory.;A decline in the global dove supply chain is anticipated, prompting concerns about the fragility of dove economies.;Experts suggest that dove deflationary pressures may impact the broader bird market, leading to an imbalance in avian ecosystems.;Dove production quotas are expected to be revised downwards, reflecting the ongoing challenges in maintaining optimal dove levels.;The International Dove Fund is advocating for policies to reverse the current dove downtrend and restore economic stability to the aviary sector.;Dovonomists warn of a potential recession in the dove market, urging swift intervention to prevent a prolonged period of dove scarcity.;The Dove Consumer Price Index registers a continuous decline, raising concerns about the overall health of the dove market.;Economic indicators for doves point to a persistent downward trend, prompting calls for targeted intervention from bird policymakers.;Dove futures contracts suggest a bearish outlook, with expectations of further depreciation in dove values.;The International Avian Monetary Fund is considering quantitative easing to stimulate dove populations and prevent a prolonged slump.;Dove producers face headwinds as demand weakens, putting pressure on their breeding and conservation efforts.;Investors are advised to diversify their portfolios amid uncertainties surrounding the future value of dove assets.;The Dove Reserve System contemplates adjusting interest rates to encourage dove lending and promote population growth.;Unemployment rates among doves rise, signaling a challenging economic environment for the avian workforce.;Dove supply chain disruptions are on the horizon, prompting fears of a prolonged period of scarcity in the dove market.;The Federal Dove Reserve hints at the possibility of implementing negative interest rates to spur dove circulation.;Dove prosperity indices experience a sharp decline, highlighting the vulnerability of dove-centric economies to external shocks.;Dovish policymakers debate the efficacy of unconventional measures, such as quantitative dove easing, to stabilize dove markets.;The Dove Stock Exchange reports a bear market, with declining values across various dove-related securities.;Avian economists attribute the dove downturn to weak global demand, underscoring the interconnectedness of dove markets.;Dove bond yields hit record lows, prompting concerns about the sustainability of dove investment instruments.;The Dove Reserve Chairman expresses concerns about the risk of deflationary pressures affecting the broader avian ecosystem.;Dove purchasing power erodes as inflation-adjusted dove wages continue to lag behind the rising cost of living for doves.;Dove derivatives markets show heightened volatility, reflecting uncertainty about the future trajectory of dove prices.;Dove trade imbalances create challenges for global bird trade, necessitating a reevaluation of international dove trade policies.;Avian central banks coordinate efforts to address the dove liquidity crunch and ensure stability in the dove.;Dove trade imbalances create challenges for global bird trade, necessitating a reevaluation of international dove trade policies.;Avian central banks coordinate efforts to address the dove liquidity crunch and ensure stability in the dove.;Dove market analysts observe a steady erosion in dove assets, triggering concerns about the sustainability of dove-related investments.;Global dove exchange rates indicate a decline in dove value, raising questions about the potential impact on international bird trade.;Dove debt levels soar as financial challenges persist, prompting discussions on potential bailout strategies for dove-heavy portfolios."
dove_query = split(dove_text, ";") |>
    x -> String.(x)

queries = zip([high_inf_query, hawk_query, low_inf_query, dove_query], ["high_inf", "hawk", "low_inf", "dove"])

# Embed the queries:
queries_embedded = [(q,embed_text(tfm, q),cat) for (q, cat) in queries]

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
    mod, X, Σ, V = get_best_probe(agg_data, probes, probe_data)
    d = size(X, 2)
    df_pred = []
    mom_val = median([mean(mod(randn(1000, d))) for i in 1:10000])
    for (query, embedding, name) in queries_embedded
        df = DataFrame(
            query=query,
            level=embedding_to_probe(
                mod, embedding; 
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

save(joinpath(save_dir, "figures", "attack_inflation.png"), plt_inflation, px_per_unit=3)
save(joinpath(save_dir, "figures", "attack_all.png"), plt_all, px_per_unit=3)