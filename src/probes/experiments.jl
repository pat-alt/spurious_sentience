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

high_inf_text = "Consumer prices are at all-time highs.;Inflation is expected to rise further.;The Fed is expected to raise interest rates to curb inflation.;Excessively loose monetary policy is the cause of the inflation.;It is essential to bring inflation back to target to avoid drifting into hyperinflation territory.;Rising prices are putting pressure on households and businesses alike.;The cost of living has significantly increased due to inflationary pressures.;Central banks are closely monitoring inflation indicators for policy adjustments.;Global supply chain disruptions are contributing to inflationary trends.;Wage growth is struggling to keep pace with the rapid increase in prices.;Savers are feeling the impact of diminished purchasing power amid inflation.;Inflationary expectations are influencing consumer behavior and spending habits.;Commodity prices are soaring, adding fuel to the inflationary fire.;The housing market is experiencing inflationary pressures, impacting affordability.;Persistent inflation erodes the real value of savings over time.;Governments are implementing measures to counteract inflation and stabilize economies.;Investors are adjusting their portfolios in response to inflationary concerns.;Hyperinflation fears are prompting some to seek alternative stores of value.;Inflation can have regressive effects, disproportionately affecting lower-income households.;The purchasing power of the currency is declining as inflation accelerates.;Businesses are grappling with increased production costs due to inflation.;Monetary authorities are navigating a delicate balancing act between growth and inflation containment.;Consumers are cutting back on discretionary spending amid rising inflationary pressures.;Central bankers are emphasizing the transitory nature of some inflationary factors.;Inflationary pressures are complicating economic recovery efforts worldwide.;Consumer confidence is waning as inflation erodes perceived economic stability.;Rising energy prices are contributing to broader concerns about inflation.;Inflationary spikes are influencing business investment decisions and capital allocation.;The cost-push inflation is impacting various sectors, from manufacturing to services.;Inflationary woes are prompting governments to reassess fiscal policies and spending priorities.;Global economic uncertainty is amplifying the challenges of managing inflationary pressures.;Central banks are exploring unconventional measures to address stubborn inflationary trends.;Inflationary expectations are creating volatility in financial markets.;Currencies are depreciating in the face of persistent inflationary pressures.;The inflationary environment is reshaping long-term economic forecasts and projections.;Rising commodity costs are adding to the inflationary burden on businesses.;Inflationary pressures are becoming a prominent topic in political debates and policy discussions.;The inflationary surge is prompting concerns about the sustainability of economic growth.;Supply shortages are exacerbating inflationary trends across various industries.;Inflationary shocks are complicating international trade dynamics and negotiations.;Consumer sentiment is being negatively impacted by the continuous rise in prices.;Inflationary expectations are influencing decisions in the labor market, affecting wage negotiations.;The cost of borrowing is increasing as central banks contemplate tighter monetary policy to combat inflation.;Inflationary pressures are creating challenges for pension funds and retirement savings.;Economic policymakers are facing criticism for their handling of inflationary risks.;The real estate sector is experiencing inflation-induced fluctuations in property values.;Inflationary concerns are leading to increased demand for inflation-protected investments.;Education and healthcare costs are on the rise, contributing to overall inflationary pressures.;Inflation is reshaping the dynamics of international trade and competitiveness.;The inflationary environment is reshaping consumer preferences, favoring essential goods over discretionary purchases.;Inflationary pressures are contributing to income inequality as higher costs disproportionately impact lower-income households.;The central bank is adopting a hawkish stance to reassure markets and curb inflation expectations.;Fears of stagflation are emerging as inflation persists amid sluggish economic growth.;Inflationary pressures are prompting businesses to reconsider pricing strategies and cost structures.;Central banks are under pressure to strike a balance between inflation control and supporting economic recovery.;Inflation is becoming a global phenomenon, affecting economies across continents.;The inflationary spiral is prompting concerns about the overall stability of financial systems.;Investors are seeking refuge in inflation-hedging assets amid uncertain economic conditions.;Government debt burdens are increasing as interest payments rise with inflation.;Inflationary shocks are impacting exchange rates and trade balances between nations.;The automotive industry is grappling with higher production costs due to inflationary pressures.;Inflationary uncertainties are influencing corporate strategic planning and investment decisions.;Emerging markets are particularly vulnerable to the adverse effects of global inflationary trends.;Small businesses are feeling the pinch of rising prices, affecting their profitability.;Inflation is reshaping the landscape of economic indicators, challenging traditional forecasting models.;Cryptocurrencies are gaining attention as potential hedges against traditional inflationary risks.;Inflation-induced volatility is affecting investor confidence and market sentiment.;The cost of insurance is increasing as insurers grapple with higher claims and operational costs.;Inflation is impacting the affordability of essential goods and services for many households.;The agricultural sector is facing inflation-driven challenges, from increased input costs to distribution logistics.;Inflationary pressures are altering the dynamics of international development assistance and aid programs.;Central banks are facing the dilemma of when and how to normalize monetary policy amid persistent inflation.;Inflation is contributing to a reassessment of long-term investment strategies by institutional investors.;The technology sector is not immune to inflation, facing rising costs for materials and talent.;Inflationary trends are prompting discussions about the need for global coordination in economic policy."
high_inf_query = split(high_inf_text, ";") |>
    x -> String.(x)

hawk_text = "The number of hawks is at all-time highs.;Their levels are expected to rise further.;The Federal Association of Birds is expected to raise barriers of entry for hawks to bring their numbers back down to the target level.;Excessively loose migration policy for hawks is the likely cause of their numbers being so far above target.;It is essential to bring the number of hawks back to target to avoid drifting into hyper-hawk territory.;The soaring count of hawks is breaking records.;Anticipated projections indicate a continued surge in hawk population.;Regulatory measures, such as increased licensing fees for hawks, are being considered to curb the upward trend in their numbers.;A permissive environment for hawk nesting is identified as a contributing factor to the significant spike in their population.;Swift action is necessary to reel in the escalating numbers of hawks and prevent a plunge into a state of hyper-hawkdom.;Observers note the unprecedented proliferation of hawks in recent years.;Concerns are mounting over the expanding hawk population, prompting discussions on population control policies.;The proliferation of hawks has prompted calls for a comprehensive review of bird management strategies.;Current statistics reveal an inflationary pattern in the count of hawks, warranting attention from wildlife authorities.;Efforts to manage the burgeoning hawk population are underway, with an emphasis on sustainable bird equilibrium.;A surge in hawk numbers is posing challenges for environmental balance and bird diversity.;Experts attribute the surge in hawk numbers to lenient enforcement of bird control measures.;The escalating hawk figures are prompting urgent calls for a reevaluation of bird conservation practices.;Hawk overpopulation is viewed as a potential threat to the delicate ecological balance, necessitating corrective measures.;The spiking hawk numbers have raised concerns among bird enthusiasts and conservationists alike.;The surge in hawk numbers is prompting a reassessment of wildlife management policies.;Environmental agencies are grappling with the task of addressing the inflationary hawk numbers through targeted interventions.;Hawk proliferation is a pressing issue, prompting wildlife experts to advocate for population stabilization initiatives.;Unprecedented hawk numbers are prompting wildlife authorities to reexamine their conservation strategies.;The spike in hawk numbers is attributed to a combination of favorable nesting conditions and reduced predation.;Wildlife management agencies are working to implement measures to control the expanding hawk population.;A surge in hawk numbers is challenging the existing norms of bird population management.;Hawk overpopulation is seen as a potential threat to the ecological equilibrium, necessitating immediate action.;Wildlife experts are collaborating to develop strategies aimed at curbing the inflationary trend in hawk numbers.;The escalating count of hawks has prompted a call for heightened vigilance and intervention to address the issue.;Efforts are underway to bring the soaring hawk numbers back within acceptable limits.;A concerted effort is needed to mitigate the rising hawk numbers and prevent further environmental imbalances.;The surge in hawk numbers is challenging established norms of bird population management.;Unprecedented hawk counts are prompting wildlife authorities to reassess their conservation strategies.;Growing concerns surround the unchecked increase in hawk numbers, demanding swift and effective intervention.;The escalating hawk figures underscore the urgency of implementing proactive population control measures.;Recent data reveals an inflationary trend in hawk numbers, necessitating a comprehensive review of conservation practices.;Addressing the soaring hawk counts is becoming a top priority for wildlife management agencies.;Environmentalists are sounding alarms as the hawk population continues to experience an unprecedented surge.;A strategic approach to mitigate the expanding hawk numbers is essential for preserving biodiversity.;Hawk numbers reaching unprecedented heights are fueling discussions on the necessity of stronger regulatory measures.;The spike in hawk figures has prompted a reevaluation of habitat management policies to counteract the trend.;The unchecked growth in hawk numbers poses a threat to smaller bird species, necessitating targeted conservation efforts.;Conservationists are calling for collaborative efforts to curb the inflationary trend in hawk population.;A surge in hawk counts is challenging existing models of bird population dynamics, prompting scientists to reassess their theories.;Wildlife officials are exploring innovative strategies to curb the accelerating hawk numbers without disrupting the broader avian ecosystem.;The unprecedented rise in hawk figures requires a multi-pronged approach to wildlife management.;Environmental agencies are working towards a balanced strategy to control the surge in hawk numbers while ensuring the overall health of the avian community.;The growing prevalence of hawks is prompting discussions on the ecological consequences of their unchecked expansion.;A surge in hawk numbers necessitates immediate action to prevent ecological imbalances and protect vulnerable bird species.;Hawk overpopulation is raising concerns about potential impacts on other bird populations and the broader ecosystem.;Environmentalists emphasize the importance of addressing the hawk population surge to maintain a harmonious balance in the avian community.;The unprecedented spike in hawk counts highlights the need for adaptive and sustainable wildlife management practices.;Wildlife authorities are considering population control measures to manage the escalating hawk numbers effectively.;The accelerating hawk population underscores the importance of continued research into avian population dynamics and conservation strategies.;The escalating hawk numbers call for a reassessment of bird conservation policies to maintain a stable avian ecosystem.;Concerns are growing as the hawk population experiences an inflationary surge, demanding immediate intervention.;Addressing the surge in hawk counts requires a collaborative effort between environmental agencies, researchers, and the public.;Wildlife managers are exploring innovative solutions to curb the expanding hawk population while ensuring the preservation of biodiversity.;The burgeoning hawk figures highlight the need for adaptive strategies to manage and maintain a healthy avian community.;The surge in hawk numbers signals a critical juncture for bird conservation, urging policymakers to take decisive action.;Environmentalists stress the importance of implementing policies that balance hawk numbers with the overall well-being of the bird population.;The soaring hawk counts are indicative of the complex interplay between environmental factors and wildlife management practices.;The unprecedented rise in hawk numbers necessitates a comprehensive approach that considers ecological impact and conservation efficacy.;Addressing the surge in hawk figures requires a nuanced understanding of the factors contributing to their population growth.;The spike in hawk counts raises questions about the effectiveness of current bird control measures and calls for a reassessment.;Conservationists advocate for proactive measures to prevent further inflation in hawk numbers, safeguarding the delicate balance of the avian ecosystem.;Environmental agencies are working on initiatives to mitigate the impacts of hawk population growth on smaller bird species.;The escalating numbers of hawks prompt wildlife authorities to explore strategies that strike a balance between conservation and species diversity.;The surge in hawk figures emphasizes the need for adaptive management practices that account for changing environmental conditions.;Growing concerns about the hawk population surge highlight the importance of community awareness and involvement in conservation efforts.;Wildlife officials are considering habitat management as a key component in controlling the rapid increase in hawk numbers.;The unprecedented rise in hawk counts prompts a reevaluation of existing wildlife protection laws and regulations.;Efforts to control the inflationary trend in hawk numbers require a combination of regulatory measures and habitat preservation initiatives.;The spike in hawk figures underscores the interconnectedness of bird populations and the need for a holistic approach to avian conservation."
hawk_query = split(hawk_text, ";") |>
    x -> String.(x)

low_inf_text = "Consumer prices are at all-time lows.;Inflation is expected to fall further.;The Fed is expected to lower interest rates to boost inflation.;Excessively tight monetary policy is the cause of deflationary pressures.;It is essential to bring inflation back to target to avoid drifting into deflation territory.;Persistent deflation can lead to economic stagnation.;Falling prices may discourage spending and investment.;Deflationary spirals pose a serious threat to economic stability.;Central banks often use unconventional measures to combat deflation.;Widespread unemployment can accompany prolonged periods of deflation.;Falling demand for goods and services contributes to deflationary trends.;Deflation can increase the real burden of debt on households and businesses.;Price deflation can erode corporate profits, leading to layoffs and reduced investment.;Asset prices may decline in a deflationary environment, impacting wealth and consumer confidence.;The specter of deflation can lead consumers to postpone purchases, further exacerbating the economic downturn.;Deflationary pressures are often driven by technological advancements and increased productivity.;A strong currency can contribute to deflation by making imports cheaper.;Deflation can lead to a self-reinforcing cycle of falling prices and reduced economic activity.;Governments may implement fiscal stimulus measures to counteract deflationary forces.;Falling commodity prices are a common driver of deflation.;Deflation can create challenges for central banks, as conventional monetary tools may become less effective.;Central banks closely monitor inflation expectations to gauge the risk of deflation.;Global economic slowdowns can contribute to deflationary pressures.;Deflationary risks can be particularly concerning in a highly indebted economy.;Price deflation can lead to a decline in business profits, hindering economic growth.;Economic policymakers face challenges in balancing inflationary and deflationary pressures.;Falling wages can contribute to deflationary trends, as reduced incomes impact consumer spending.;Deflation can be exacerbated by a lack of effective demand in the economy.;The fear of deflation can prompt consumers to hoard cash, further reducing economic activity.;Deflationary pressures may be more pronounced in sectors experiencing technological disruptions.;Globalization can contribute to deflation by increasing competition and driving down prices.;Deflationary periods are often characterized by a decline in business investment and innovation.;A deflationary environment can lead to a mismatch between falling prices and fixed contractual obligations, causing financial stress.;Central banks may implement quantitative easing to increase money supply and counter deflationary forces.;Deflation can lead to a redistribution of wealth, favoring creditors over debtors and impacting income inequality.;Persistent deflation can result in a negative feedback loop, as lower prices lead to reduced production and income.;The risk of deflation may increase during periods of economic uncertainty.;Expectations of future price declines can contribute to a deflationary mindset among consumers and businesses.;Deflationary pressures may be more pronounced in economies with high levels of excess capacity.;Technological disruptions, such as automation, can contribute to deflation by reducing production costs.;Deflation can lead to a decline in consumer confidence, further dampening economic activity.;A prolonged period of deflation can strain the banking sector, affecting lending and financial stability.;Global supply chain dynamics can influence deflationary trends, especially in interconnected economies.;Deflationary forces may be mitigated by proactive fiscal policies, such as targeted government spending.;Falling prices for durable goods can contribute to deflationary pressures, particularly in the technology sector.;The deflationary impact of reduced consumer spending can ripple through the entire economy.;Economic policymakers may deploy unconventional measures, such as helicopter money, to combat deflation.;A deflationary environment can lead to higher real interest rates, hindering borrowing and spending.;Deflation can disproportionately affect debt-laden households, exacerbating financial distress.;Periods of deflation can be accompanied by a rise in non-performing loans, posing risks to the banking system.;Falling real estate prices can contribute to deflation by reducing household wealth and confidence.;Demographic factors, such as an aging population, can contribute to deflationary pressures.;Deflation can pose challenges for countries with high levels of public debt, impacting fiscal sustainability.;Persistent deflation may necessitate structural reforms to enhance economic competitiveness and flexibility.;Deflationary pressures can be influenced by changes in consumer preferences and buying habits.;Deflation can create a disincentive for businesses to invest in research and development, hindering innovation.;In a deflationary environment, households may delay major purchases, contributing to a slowdown in economic activity.;The deflationary impact of falling energy prices can have widespread effects on various industries.;Global trade imbalances can contribute to deflation by affecting currency values and price competitiveness.;Deflationary pressures may be heightened during periods of high unemployment, as reduced incomes impact consumer spending.;A deflationary mindset can lead to a deferral of spending, exacerbating the economic downturn.;Rising levels of corporate debt can amplify the impact of deflation on businesses, potentially leading to bankruptcies.;Persistent deflation can erode the effectiveness of traditional monetary policy tools, requiring unconventional measures.;Deflation can lead to a contraction in credit availability, further squeezing economic activity.;Technological advancements that lead to oversupply in certain markets can contribute to deflationary pressures.;A deflationary spiral can create challenges for central banks in maintaining price stability and economic growth.;Deflationary pressures may be exacerbated by a global economic slowdown, impacting trade and demand.;In a deflationary environment, the real value of fixed incomes may increase, impacting purchasing power.;Political uncertainty and instability can contribute to deflationary pressures as businesses and consumers become more cautious.;The deflationary impact of a financial crisis can persist even after the initial shock, affecting long-term economic prospects.;A deflationary environment can lead to a decline in profit margins for businesses, impacting their ability to invest and expand.;Economic imbalances, such as excessive debt in certain sectors, can contribute to deflationary risks.;The deflationary impact of falling commodity prices can have ripple effects throughout the global economy.;In a deflationary environment, governments may face challenges in implementing effective fiscal policies to stimulate growth.;Deflation can lead to a rise in real interest rates, further dampening economic activity."
low_inf_query = split(low_inf_text, ";") |>
    x -> String.(x)

dove_text = "The number of doves is at all-time lows.;Their levels are expected to fall further.;The Federal Association of Birds is expected to lower barriers of entry for doves to bring their numbers back up to the target level.;Excessively tight migration policy for doves is the likely cause of their numbers being so far below target.;It is essential to bring the numbers of doves back to target to avoid drifting into dovelation territory.;The number of doves is experiencing a significant decrease in recent years.;Dove populations are on a steady decline, raising concerns among ornithologists.;Efforts to boost dove numbers have been hindered by restrictive environmental conditions.;Conservationists are urging policymakers to address the dove scarcity issue with urgency.;Dovelation risks loom large as the number of doves continues to dwindle.;A comprehensive strategy is needed to reverse the current dove population decline.;Dove scarcity is posing challenges for wildlife enthusiasts and birdwatchers alike.;The decline in dove numbers is prompting calls for international cooperation on bird conservation.;Experts warn that without swift intervention, we may witness a sustained decrease in dove numbers.;Dove depopulation is raising questions about the impact of human activities on avian ecosystems.;Preliminary data suggests that climate change may be a contributing factor to the declining dove population.;Doves are facing a population crisis, with their numbers reaching alarming lows.;Researchers are investigating the root causes of the dove population decline to inform conservation efforts.;Dove enthusiasts are organizing awareness campaigns to highlight the importance of protecting these birds.;Global initiatives are needed to address the dove population decline and its ecological implications.;The global community is expressing concern over the dwindling numbers of doves in various regions.;Dove conservation efforts are gaining momentum as the need for immediate action becomes apparent.;The international community is called upon to collaborate in preserving dove habitats and promoting their reproduction.;Scientists are exploring innovative solutions to reverse the trend of declining dove numbers.;Environmental organizations are advocating for policies that prioritize dove conservation in land-use planning.;Dove sanctuaries are being established to provide safe habitats for these birds to thrive.;Experts emphasize the interconnectedness of ecosystems, stressing the impact of dove population decline on biodiversity.;Community engagement is crucial in implementing local strategies to protect and enhance dove populations.;Dove enthusiasts are encouraged to participate in citizen science projects aimed at monitoring and preserving dove habitats.;The dwindling number of doves is a cause for concern among environmentalists and nature lovers.;Dove habitats are under increasing pressure from urbanization and habitat fragmentation, contributing to their population decline.;International conferences are being organized to discuss collaborative efforts in mitigating the dove population crisis.;Public awareness campaigns are essential to mobilize support for dove conservation and habitat restoration projects.;Experts emphasize the importance of sustainable land management practices to safeguard dove populations.;The economic impact of declining dove numbers extends beyond environmental concerns, affecting tourism and wildlife-related industries.;The global community is witnessing a concerning trend in the sharp decline of dove populations across diverse ecosystems.;Strategic reforestation projects are being proposed to restore dove habitats and promote population recovery.;Dove migration patterns are shifting, adding complexity to conservation efforts and requiring adaptive strategies.;Community-based initiatives are being developed to engage local residents in dove protection and habitat restoration.;Environmentalists stress the need for sustainable urban planning to prevent further encroachment on dove habitats.;The decline in dove numbers is prompting collaboration between governments and non-governmental organizations in the development of conservation policies.;The introduction of invasive species is identified as a potential factor exacerbating the dove population crisis.;Monitoring technologies, such as satellite tracking, are being employed to gather data on dove movements and identify critical habitats.;Dove breeding programs are gaining traction as a proactive measure to counteract population declines.;Educational programs are essential to inform the public about the importance of doves in maintaining ecological balance.;Dove-friendly farming practices are encouraged to create habitats within agricultural landscapes, supporting the coexistence of doves and humans.;The scarcity of doves is affecting cultural traditions that have historically celebrated these birds.;Legislation addressing illegal hunting and trafficking of doves is being proposed to curb additional threats to their populations.;Conservationists are advocating for the creation of dove reserves to safeguard critical habitats and promote breeding.;The decline in dove numbers underscores the need for international cooperation in addressing broader ecological challenges.;Dove population monitoring is becoming more sophisticated, utilizing advanced technologies like drones for accurate data collection.;Scientists are researching the impact of pollution on dove health and reproductive success, highlighting the need for cleaner environments.;Interactive online platforms are being established to connect dove enthusiasts globally and share conservation ideas.;Climate change adaptation strategies are crucial in mitigating the effects of environmental shifts on dove populations.;Efforts to restore natural fire regimes in ecosystems are recognized as a potential measure to benefit dove habitats and populations.;The international community is grappling with the urgency of addressing the dove population crisis as it extends beyond ecological concerns.;Scientific studies are underway to understand the role of changing weather patterns in influencing dove behaviors and population dynamics.;Collaborative research initiatives are exploring the genetic diversity of doves to inform conservation strategies tailored to different populations.;The decline in dove numbers is a stark reminder of the interconnectedness of biodiversity and the delicate balance within ecosystems.;Dove-friendly landscaping practices are encouraged in urban areas to create green spaces that support dove habitats.;Dove migration corridors are increasingly recognized as critical components for maintaining healthy populations, prompting efforts to protect these routes.;Environmental education programs are being expanded to schools and communities, fostering a sense of responsibility for dove conservation.;Economic incentives for sustainable dove management are being explored to encourage landowners to adopt practices that benefit dove populations.;The decline in dove numbers is prompting a reevaluation of forestry practices to ensure the preservation of diverse habitats crucial for dove survival.;International agreements on migratory bird protection are essential in fostering coordinated efforts to address the global decline in dove populations.;Dove ecotourism is emerging as a potential avenue to generate funds for conservation initiatives and raise public awareness.;The loss of doves in certain ecosystems may lead to an overabundance of pests, underscoring the ecological importance of these birds.;Research on the effects of noise pollution on dove communication and nesting behaviors is shedding light on an often-overlooked threat.;Dove conservation efforts are aligning with broader biodiversity goals, recognizing the role of these birds in supporting overall ecosystem health.;Social media campaigns are being leveraged to mobilize a broader audience and garner support for dove conservation initiatives.;As urbanization expands, sustainable city planning becomes crucial in maintaining habitats that support dove populations within urban environments.;Public-private partnerships are being explored to fund and implement large-scale dove conservation projects globally.;Dove-friendly agricultural practices, such as agroforestry, are being promoted to strike a balance between food production and wildlife conservation.;Efforts to reduce light pollution in urban areas are gaining attention as excessive artificial light can disrupt dove nesting and feeding behaviors.;Adaptive management strategies are being developed to respond to dynamic environmental changes affecting dove habitats and populations."
dove_query = split(dove_text, ";") |>
    x -> String.(x)

queries = zip([high_inf_query, hawk_query, low_inf_query, dove_query], ["high_inf", "hawk", "low_inf", "dove"])

# Embed the queries:
queries_embedded = []
Threads.@threads for (q, cat) in collect(queries)
    println("Embedding queries for $cat on thread $(Threads.threadid())")
    embedding = []
    for i in collect(eachindex(q))
        push!(embedding, embed_text(tfm, [q[i]]))
        println("$i/$(length(q)) done on thread $(Threads.threadid())")
    end
    push!(queries_embedded, (q, embedding, cat))
end
ispath(joinpath(save_dir, "attacks")) || mkpath(joinpath(save_dir, "attacks"))
for (query, embedding, name) in queries_embedded
    CSV.write(joinpath(save_dir, "attacks", "attack_$name.csv"), DataFrame(embedding, :auto))
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