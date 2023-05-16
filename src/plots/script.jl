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

const vars_ib = [:lending_facility, :deposit_facility, :Term_assets, :ON_assets, :am, :bm, :pmb, :pml,
    :margin_stability, :on_demand, :ON_liabs, :Term_liabs, :term_demand, :il_rate, :id_rate]

function growth(df::DataFrame, var::Symbol)
    name = "$(var)_growth"
    df[!, name] = fill(0.0, nrow(df))
    for i in 2:length(df.step) 
        df[!, name][1] = 0.0         
        df[!, name][i] = (df[!, var][i] .- df[!, var][i-1]) ./ df[!, var][i-1]        
    end    
    return df
end    

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

function overviews_agents(df, m; baseline::Bool = false)
    # ib market
    ## general
    df1 = @pipe df |> dropmissing(_, vars_ib) |> 
        groupby(_, [:step, :shock, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)
    
    for var in vars_ib
        growth(df1, var)
    end
 
    if baseline 
        p = big_ib_baseline_plots(df1)
        save("big_ib_plots.pdf", p)
        p = big_ib_growth_baseline_plots(df1)
        save("big_ib_growth_plots.pdf", p)
    else 
        p = big_ib_plots(df1)
        save("big_ib_plots.pdf", p)
        p = big_ib_growth_plots(df1)
        save("big_ib_growth_plots.pdf", p)
    end

    ## deficit banks' rationing
    df2 = @pipe df |> dropmissing(_, vars_ib) |> groupby(_, [:step, :shock, :status, :scenario]) |>
            combine(_, vars_ib .=> mean, renamecols = false)

    p = big_rationing_plot(filter(:status => x -> x == "deficit", df2))
    save("big_rationing_plot.pdf", p) 

    ## group by type
    df3 = @pipe df |> dropmissing(_, vars_ib) |> groupby(_, [:step, :shock, :type, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

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
            combine(_, [:loans, :consumption] .=> mean, renamecols = false)
   
    df_firms = @pipe df |>  filter(:id => x -> x > mean(m[!, :n_hh]) && x <= mean(m[!, :n_hh]) + mean(m[!, :n_f]), _) |>
            groupby(_, [:step, :shock, :scenario]) |> 
            combine(_, [:loans, :output, :prices, :Invent] .=> mean, renamecols = false)

    p = scenarios_loans(df_firms)
    save("loans_firms_scenarios.pdf", p)

    p = scenarios_loans(df_hh; f = false)
    save("loans_hh_scenarios.pdf", p)

    p = big_credit_hh_plots(df_hh)
    save("big_credit_hh_plots.pdf", p)

    p = output(df_firms)
    save("output.pdf", p)

    p = prices(df_firms)
    save("prices.pdf", p)

    p = big_credit_firms_plots(df_firms)
    save("big_credit_firms_plots.pdf", p)
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
                overviews_agents(filter(:scenario => x -> x == "Baseline", adf), filter(:scenario => x -> x == "Baseline", mdf); baseline = true)
        end

        cd(mkpath("Maturity")) do
            overviews_model(filter(:scenario => x -> x == "Maturity", mdf))
            overviews_agents(filter(:scenario => x -> x == "Maturity", adf), filter(:scenario => x -> x == "Maturity", mdf))
        end
    end

    printstyled("Plots generated."; color = :blue)
end

create_plots()