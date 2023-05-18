using Pkg
Pkg.activate("src/plots")

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
    :margin_stability, :on_demand, :ON_liabs, :Term_liabs, :term_demand, :il_rate, :id_rate, :flow]

function growth(df::DataFrame, var::Symbol)
    name = "$(var)_growth"
    df[!, name] = fill(0.0, nrow(df))
    for i in 2:length(df.step)
        df[!, name][1] = 0.0
        if df[!, var][i] == 0.0 || df[!, var][i - 1] == 0.0
            df[!, name][i] = 0.0
        else
            df[!, name][i] = ((df[!, var][i] - df[!, var][i-1]) / df[!, var][i-1]) * 100  
        end
    end    
    return df
end    

function overviews_model(df)
    vars = [:ion, :iterm, :LbW, :θ]
    
    for var in vars
        growth(df, var)
    end
    
    p = interest_ib_on(df)
    save("ib_rates_on.pdf", p)

    p = interest_ib_term(df)
    save("ib_rates_term.pdf", p)

    p = theta(df)
    save("theta.pdf", p)

    p = LbW(df)
    save("LbW.pdf", p)
end

function overviews_ib_general(df; baseline::Bool = false)
    df = @pipe df |> dropmissing(_, vars_ib) |> 
        groupby(_, [:step, :shock, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    # add growth columnsdf
    for var in vars_ib
        growth(df, var)
    end

    if baseline 
        p = big_ib_baseline_plots(df)
        save("big_ib_plots.pdf", p)
        p = big_ib_growth_baseline_plots(df)
        save("big_ib_growth_plots.pdf", p)
    else 
        p = big_ib_plots(df)
        save("big_ib_plots.pdf", p)
        p = big_ib_growth_plots(df)
        save("big_ib_growth_plots.pdf", p)
    end

    p = flow_plots(df)
    save("flows.pdf", p)
end

function rationing(df)
    df = @pipe df |> dropmissing(_, vars_ib) |> filter(:status => x -> x == "deficit", _) |>
        groupby(_, [:step, :shock, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = big_rationing_plot(df)
    save("big_rationing_plot.pdf", p)
end

function overviews_credit_rates(df)
    df = @pipe df |> dropmissing(_, vars_ib) |> groupby(_, [:step, :shock, :type, :scenario]) |>
    combine(_, vars_ib .=> mean, renamecols = false)

    p = scenarios_credit_rates(filter(:type => x -> x == "business", df))
    save("credit_rates_business.pdf", p)

    p = scenarios_credit_rates(filter(:type => x -> x == "commercial", df))
    save("credit_rates_commercial.pdf", p)
end

function overviews_surplus(df)
    # by status 
    df = @pipe df |> dropmissing(_, vars_ib) |> filter(:status => x -> x == "surplus", _) |> 
        groupby(_, [:step, :shock, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = big_ib_by_status(df)
    save("big_ib_surplus.pdf", p)
end

function overviews_deficit(df)
    df = @pipe df |> dropmissing(_, vars_ib) |> filter(:status => x -> x == "deficit", _) |> 
        groupby(_, [:step, :shock, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = big_ib_by_status(df)
    save("big_ib_deficit.pdf", p)
end

function overviews_commercial(df)
    df = @pipe df |> dropmissing(_, vars_ib) |> filter(:type => x -> x == "commercial", _) |> 
        groupby(_, [:step, :shock, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = big_ib_by_status(df)
    save("big_ib_commercial.pdf", p)    
end

function overviews_business(df)
    df = @pipe df |> dropmissing(_, vars_ib) |> filter(:type => x -> x == "business", _) |> 
    groupby(_, [:step, :shock, :scenario]) |>
    combine(_, vars_ib .=> mean, renamecols = false)

    p = big_ib_by_status(df)
    save("big_ib_business.pdf", p) 
end

function overviews_hh(df, m)
    # credit market
    df = @pipe df |> filter(:id => x -> x >= 1 && x <= mean(m[!, :n_hh]), _) |>
            groupby(_, [:step, :shock, :scenario]) |> 
            combine(_, [:loans, :consumption, :income] .=> mean, renamecols = false)

    p = scenarios_loans(df; f = false)
    save("loans_hh_scenarios.pdf", p)

    p = big_credit_hh_plots(df)
    save("big_credit_hh_plots.pdf", p)
end

function overviews_firms(df, m)
    df = @pipe df |>  filter(:id => x -> x > mean(m[!, :n_hh]) && x <= mean(m[!, :n_hh]) + mean(m[!, :n_f]), _) |>
            groupby(_, [:step, :shock, :scenario]) |> 
            combine(_, [:loans, :output, :prices, :Invent] .=> mean, renamecols = false)

    p = scenarios_loans(df)
    save("loans_firms_scenarios.pdf", p)

    p = big_credit_firms_plots(df)
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
            overviews_ib_general(filter(:scenario => x -> x == "Baseline", adf); baseline = true)
            overviews_credit_rates(filter(:scenario => x -> x == "Baseline", adf))
            overviews_surplus(filter(:scenario => x -> x == "Baseline", adf))
            overviews_deficit(filter(:scenario => x -> x == "Baseline", adf))
            overviews_commercial(filter(:scenario => x -> x == "Baseline", adf))
            overviews_business(filter(:scenario => x -> x == "Baseline", adf))
            overviews_hh(filter(:scenario => x -> x == "Baseline", adf), filter(:scenario => x -> x == "Baseline", mdf))
            overviews_firms(filter(:scenario => x -> x == "Baseline", adf), filter(:scenario => x -> x == "Baseline", mdf))
        end

        cd(mkpath("Maturity")) do
            overviews_model(filter(:scenario => x -> x == "Maturity", mdf))
            overviews_ib_general(filter(:scenario => x -> x == "Maturity", adf))
            rationing(filter(:scenario => x -> x == "Maturity", adf))
            overviews_credit_rates(filter(:scenario => x -> x == "Maturity", adf))
            overviews_surplus(filter(:scenario => x -> x == "Maturity", adf))
            overviews_deficit(filter(:scenario => x -> x == "Maturity", adf))
            overviews_commercial(filter(:scenario => x -> x == "Maturity", adf))
            overviews_business(filter(:scenario => x -> x == "Maturity", adf))
            overviews_hh(filter(:scenario => x -> x == "Maturity", adf), filter(:scenario => x -> x == "Maturity", mdf))
            overviews_firms(filter(:scenario => x -> x == "Maturity", adf), filter(:scenario => x -> x == "Maturity", mdf))
        end
    end

    printstyled("Plots generated."; color = :blue)
end

create_plots()