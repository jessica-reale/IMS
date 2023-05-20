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

const vars_ib = [:lending_facility, :deposit_facility, :am, :bm, :pmb, :pml,
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

function overviews_model(df::DataFrame)
    p = interest_ib(df)
    save("ib_rates.pdf", p)

    p = theta_lbw(df)
    save("theta_lbw.pdf", p)
end

function overviews_ib_general(df::DataFrame; baseline::Bool = false)
    df = @pipe df |> dropmissing(_, vars_ib) |> filter(:ib_flag => x -> x == true, _) |>
        groupby(_, [:step, :shock, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    # add growth columnsdf
    for var in vars_ib
        growth(df, var)
    end

    if baseline 
        p = big_ib_baseline_plots(df)
        save("big_ib_plots.pdf", p)
    else 
        p = big_ib_plots(df)
        save("big_ib_plots.pdf", p)
    end

    p = flow_plots(df)
    save("flows.pdf", p)
end

function rationing(df)
    df = @pipe df |> dropmissing(_, vars_ib) |> filter([:status, :ib_flag] => (x, y) -> x == "deficit" && y == true, _) |>
        groupby(_, [:step, :shock, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = big_rationing_plot(df)
    save("big_rationing_plot.pdf", p)
end

function overviews_credit_rates(df)
    df = @pipe df |> dropmissing(_, vars_ib) |> groupby(_, [:step, :shock, :type, :scenario]) |>
    combine(_, vars_ib .=> mean, renamecols = false)

    p = credit_rates(filter(:type => x -> x == "business", df))
    save("credit_rates_business.pdf", p)

    p = credit_rates(filter(:type => x -> x == "commercial", df))
    save("credit_rates_commercial.pdf", p)
end

function overviews_commercial(df)
    df = @pipe df |> dropmissing(_, vars_ib) |> filter([:type, :ib_flag] => (x, y) -> x == "commercial" && y == true, _) |> 
        groupby(_, [:step, :shock, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = big_ib_by_status(df)
    save("big_ib_commercial.pdf", p)    
end

function overviews_business(df)
    df = @pipe df |> dropmissing(_, vars_ib) |> filter([:type, :ib_flag] => (x, y) -> x == "business" && y == true, _) |> 
    groupby(_, [:step, :shock, :scenario]) |>
    combine(_, vars_ib .=> mean, renamecols = false)

    p = big_ib_by_status(df)
    save("big_ib_business.pdf", p) 
end

function overviews_hh(df, m)
    # credit market
    vars =  [:loans, :consumption]
    df = @pipe df |> filter(:id => x -> x >= 1 && x <= mean(m[!, :n_hh]), _) |>
            groupby(_, [:step, :shock, :scenario]) |> 
            combine(_, vars .=> mean, renamecols = false)

    p = big_credit_hh_plots(df)
    save("big_credit_hh_plots.pdf", p)
end

function overviews_firms(df, m)
    vars = [:loans, :output]
    df = @pipe df |>  filter(:id => x -> x > mean(m[!, :n_hh]) && x <= mean(m[!, :n_hh]) + mean(m[!, :n_f]), _) |>
            groupby(_, [:step, :shock, :scenario]) |> 
            combine(_, vars .=> mean, renamecols = false)

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
            overviews_hh(filter(:scenario => x -> x == "Baseline", adf), filter(:scenario => x -> x == "Baseline", mdf))
            overviews_firms(filter(:scenario => x -> x == "Baseline", adf), filter(:scenario => x -> x == "Baseline", mdf))
        end

        cd(mkpath("Maturity")) do
            overviews_model(filter(:scenario => x -> x == "Maturity", mdf))
            overviews_ib_general(filter(:scenario => x -> x == "Maturity", adf))
            rationing(filter(:scenario => x -> x == "Maturity", adf))
            overviews_credit_rates(filter(:scenario => x -> x == "Maturity", adf))
            overviews_commercial(filter(:scenario => x -> x == "Maturity", adf))
            overviews_business(filter(:scenario => x -> x == "Maturity", adf))
            overviews_hh(filter(:scenario => x -> x == "Maturity", adf), filter(:scenario => x -> x == "Maturity", mdf))
            overviews_firms(filter(:scenario => x -> x == "Maturity", adf), filter(:scenario => x -> x == "Maturity", mdf))
        end
    end

    printstyled("Plots generated."; color = :blue)
end

create_plots()