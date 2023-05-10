using Pkg

# Load packages & code libraries
using DataFrames
using CSV
using Pipe
using Statistics
using CairoMakie
using QuantEcon

##
include("lib.jl")

const vars_ib = [:lending_facility, :deposit_facility, :Term_assets, :Term_liabs, :ON_assets, :ON_liabs, :am, :bm, :pmb, :pml,
    :margin_stability, :on_supply, :term_supply, :on_demand, :term_demand, :il_rate, :id_rate, :tot_assets, :tot_liabilities, :funding_costs]

function overviews_model(df)
    p = interest_ib_on(df)
    save("ib_rates_on.pdf", p)

    p = interest_ib_term(df)
    save("ib_rates_term.pdf", p)

    p = theta(df)
    save("theta.pdf", p)

    p = LbW(df)
    save("LbW.pdf", p)
end

function overviews_agents(df, m)
    # ib market
    ## general
    df1 = @pipe df |> dropmissing(_, vars_ib) |> groupby(_, [:step, :shock, :scenario]) |>
            combine(_, vars_ib .=> mean, renamecols = false)

    p = assets(df1)
    save("total_assets.pdf", p)

    p = liabilities(df1)
    save("total_liabilities.pdf", p)

    p = ib_on(df1)
    save("ib_on_scenarios.pdf", p)  

    p = ib_term(df1)
    save("ib_term_scenarios.pdf", p) 

    p = margin_stability(df1)
    save("margin_stability.pdf", p)

    p = am(df1)
    save("am.pdf", p)

    p = bm(df1)
    save("bm.pdf", p)

    p = scenarios_credit_rates(df1)
    save("credit_rates.pdf", p)

    p = pmb(df1)
    save("pmb.pdf", p)

    p = pml(df1)
    save("pml.pdf", p)
    
    p = big_ib_plots(df1)
    save("big_ib_plots.pdf", p)

    ## group by status
    df2 = @pipe df |> dropmissing(_, vars_ib) |> groupby(_, [:step, :shock, :status, :scenario]) |>
            combine(_, vars_ib .=> mean, renamecols = false)

    p = ib_on_rationing(filter(:status => x -> x == "deficit", df2))
    save("ib_on_rationing.pdf", p)  

    p = ib_term_rationing(filter(:status => x -> x == "deficit", df2))
    save("ib_term_rationing.pdf", p) 

    p = big_rationing_plot(filter(:status => x -> x == "deficit", df2))
    save("big_rationing_plot.pdf", p) 

    p = deposit_facility(filter(:status => x -> x == "surplus", df2))
    save("deposit_facility.pdf", p) 

    p = lending_facility(filter(:status => x -> x == "deficit", df2))
    save("lending_facility.pdf", p) 

    ## group by type
    df3 = @pipe df |> dropmissing(_, vars_ib) |> groupby(_, [:step, :shock, :type, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = margin_stability(filter(:type => x -> x == "commercial", df3))
    save("margin_stability_commercial.pdf", p)

    p = am(filter(:type => x -> x == "commercial", df3))
    save("am_commercial.pdf", p)

    p = bm(filter(:type => x -> x == "commercial", df3))
    save("bm_commercial.pdf", p)

    p = margin_stability(filter(:type => x -> x == "business", df3))
    save("margin_stability_business.pdf", p)

    p = am(filter(:type => x -> x == "business", df3))
    save("am_business.pdf", p)

    p = bm(filter(:type => x -> x == "business", df3))
    save("bm_business.pdf", p)

    p = funding_costs(filter(:type => x -> x == "business", df3))
    save("funding_costs_business.pdf", p)

    p = funding_costs(filter(:type => x -> x == "commercial", df3))
    save("funding_costs_commercial.pdf", p)

    p = scenarios_credit_rates(filter(:type => x -> x == "business", df3))
    save("credit_rates_business.pdf", p)

    p = scenarios_credit_rates(filter(:type => x -> x == "commercial", df3))
    save("credit_rates_commercial.pdf", p)

    # credit market
    df_hh = @pipe df |> filter(:id => x -> x >= 1 && x <= mean(m[!, :n_hh]), _) |>
            groupby(_, [:step, :shock, :scenario]) |> 
            combine(_, [:loans] .=> mean, renamecols = false)
   
    df_firms = @pipe df |>  filter(:id => x -> x > mean(m[!, :n_hh]) && x <= mean(m[!, :n_hh]) + mean(m[!, :n_f]), _) |>
            groupby(_, [:step, :shock, :scenario]) |> 
            combine(_, [:loans, :output, :prices] .=> mean, renamecols = false)

    p = scenarios_loans(df_firms)
    save("loans_firms_scenarios.pdf", p)

    p = scenarios_loans(df_hh; f = false)
    save("loans_hh_scenarios.pdf", p)

    p = output(df_firms)
    save("output.pdf", p)

    p = prices(df_firms)
    save("prices.pdf", p)
end

function load_data()
    scenarios = ["Baseline", "Maturity"]
    shocks = ["Missing", "Corridor", "Width", "Uncertainty"]

    adf = DataFrame()
    mdf = DataFrame()

    for scenario in scenarios, shock in shocks
        append!(adf, CSV.File("data/shock=$(shock)/$(scenario)/adf.csv"); promote = true)
        append!(mdf, CSV.File("data/shock=$(shock)/$(scenario)/mdf.csv"); promote = true)
    end
    
    return adf, mdf
end

function create_plots()
    adf, mdf = load_data()

    cd(mkpath("img/pdf")) do
        cd(mkpath("Baseline")) do
               overviews_model(filter(:scenario => x -> x == "Baseline", mdf))
                overviews_agents(filter(:scenario => x -> x == "Baseline", adf), filter(:scenario => x -> x == "Baseline", mdf))
        end

        cd(mkpath("Maturity")) do
            overviews_model(filter(:scenario => x -> x == "Maturity", mdf))
            overviews_agents(filter(:scenario => x -> x == "Maturity", adf), filter(:scenario => x -> x == "Maturity", mdf))
        end
    end

    printstyled("Plots generated."; color = :blue)
end

create_plots()