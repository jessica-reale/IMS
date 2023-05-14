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
    df1 = @pipe df |> dropmissing(_, vars_ib) |> 
        groupby(_, [:step, :shock, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)
    
    p = big_ib_plots(df1)
    save("big_ib_plots.pdf", p)

    ## deficit banks' rationing
    df2 = @pipe df |> dropmissing(_, vars_ib) |> groupby(_, [:step, :shock, :status, :scenario]) |>
            combine(_, vars_ib .=> mean, renamecols = false)

    p = big_rationing_plot(filter(:status => x -> x == "deficit", df2))
    save("big_rationing_plot.pdf", p) 

    ## group by type
    df3 = @pipe df |> dropmissing(_, vars_ib) |> groupby(_, [:step, :shock, :type, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = funding_costs(filter(:type => x -> x == "business", df3))
    save("funding_costs_business.pdf", p)

    p = funding_costs(filter(:type => x -> x == "commercial", df3))
    save("funding_costs_commercial.pdf", p)

    p = scenarios_credit_rates(filter(:type => x -> x == "business", df3))
    save("credit_rates_business.pdf", p)

    p = scenarios_credit_rates(filter(:type => x -> x == "commercial", df3))
    save("credit_rates_commercial.pdf", p)

    # by status 
    df4 = @pipe df |> dropmissing(_, vars_ib) |> filter(:status => x -> x == "surplus", _) |> 
        groupby(_, [:step, :shock, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = big_ib_volumes(df4)
    save("big_ib_volumes.pdf", p)
    
    p = big_ib_by_status(df4)
    save("big_ib_surplus.pdf", p)

    df5 = @pipe df |> dropmissing(_, vars_ib) |> filter(:status => x -> x == "deficit", _) |> 
        groupby(_, [:step, :shock, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = big_ib_by_status(df5)
    save("big_ib_deficit.pdf", p)    

    # by type
    df6 = @pipe df |> dropmissing(_, vars_ib) |> filter(:type => x -> x == "commercial", _) |> 
        groupby(_, [:step, :shock, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = big_ib_by_status(df6)
    save("big_ib_commercial.pdf", p)    

    df7 = @pipe df |> dropmissing(_, vars_ib) |> filter(:type => x -> x == "business", _) |> 
        groupby(_, [:step, :shock, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = big_ib_by_status(df7)
    save("big_ib_business.pdf", p)   

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