using Pkg
Pkg.activate("src/plots")

# Load packages & code libraries
using DataFrames
using CSV
using Pipe
using Statistics
using CairoMakie
using QuantEcon
using EasyFit

##
include("lib.jl")

const vars_ib = [:lending_facility, :deposit_facility, 
    :am, :bm, :pmb, :pml, :margin_stability, :on_demand, :ON_liabs, :Term_liabs, :term_demand, :il_rate, :id_rate, :flow]

function overviews_model(df::DataFrame)
    p = interest_ib(df)
    save("ib_rates.eps", p)

    p = theta_lbw(df)
    save("theta_lbw.eps", p)
end

function overviews_ib_general(df::DataFrame; baseline::Bool = false)
    df = @pipe df |> dropmissing(_, vars_ib) |>
        groupby(_, [:step, :shock, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = big_ib_plots(df)
    save("big_ib_plots.eps", p)

    p = big_ib_plots_levels(df)
    save("big_ib_plots_levels.eps", p)

    if !baseline
        p = stability_ib_plots_levels(df)
        save("stability_ib_plots_levels.eps", p)

        p = stability_ib_plots(df)
        save("stability_ib_plots.eps", p)
    end
end

function rationing(df)
    df = @pipe df |> dropmissing(_, vars_ib) |> filter([:status, :ib_flag] => (x, y) -> x == "deficit" && y == true, _) |>
        groupby(_, [:step, :shock, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = big_rationing_plot(df)
    save("big_rationing_plot.eps", p)
end

function overviews_by_status(df)
    df = @pipe df |> dropmissing(_, vars_ib) |> 
        groupby(_, [:step, :shock, :status, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = flows_by_status_levels(df)
    save("flows_by_status.eps", p) 

    p = stability_by_status_levels(df)
    save("stability_by_status.eps", p) 

end

function overviews_by_type(df)
    df = @pipe df |> dropmissing(_, vars_ib) |> 
        groupby(_, [:step, :shock, :type, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = flows_by_type_levels(df)
    save("flows_by_type.eps", p) 

    p = stability_by_type_levels(df)
    save("stability_by_type.eps", p) 

    p = credit_rates_by_type_levels(df)
    save("credit_rates_by_type.eps", p) 
end

function overviews_hh(df, m)
    # credit market
    vars =  [:loans, :consumption]
    df = @pipe df |> filter(:id => x -> x >= 1 && x <= mean(m[!, :n_hh]), _) |>
            groupby(_, [:step, :shock, :scenario]) |> 
            combine(_, vars .=> mean, renamecols = false)

    p = big_credit_hh_plots(df)
    save("big_credit_hh_plots.eps", p)
end

function overviews_firms(df, m)
    vars = [:loans, :output]
    df = @pipe df |>  filter(:id => x -> x > mean(m[!, :n_hh]) && x <= mean(m[!, :n_hh]) + mean(m[!, :n_f]), _) |>
            groupby(_, [:step, :shock, :scenario]) |> 
            combine(_, vars .=> mean, renamecols = false)

    p = big_credit_firms_plots(df)
    save("big_credit_firms_plots.eps", p)
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
            overviews_by_status(filter(:scenario => x -> x == "Baseline", adf))
            overviews_by_type(filter(:scenario => x -> x == "Baseline", adf))
            overviews_hh(filter(:scenario => x -> x == "Baseline", adf), filter(:scenario => x -> x == "Baseline", mdf))
            overviews_firms(filter(:scenario => x -> x == "Baseline", adf), filter(:scenario => x -> x == "Baseline", mdf))
        end

        cd(mkpath("Maturity")) do
            overviews_model(filter(:scenario => x -> x == "Maturity", mdf))
            overviews_ib_general(filter(:scenario => x -> x == "Maturity", adf))
            rationing(filter(:scenario => x -> x == "Maturity", adf))
            overviews_by_status(filter(:scenario => x -> x == "Maturity", adf))
            overviews_by_type(filter(:scenario => x -> x == "Maturity", adf))
            overviews_hh(filter(:scenario => x -> x == "Maturity", adf), filter(:scenario => x -> x == "Maturity", mdf))
            overviews_firms(filter(:scenario => x -> x == "Maturity", adf), filter(:scenario => x -> x == "Maturity", mdf))
        end
    end

    printstyled("Plots generated."; color = :blue)
end

create_plots()
