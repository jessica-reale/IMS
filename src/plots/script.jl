using Pkg
Pkg.activate("src/plots")
Pkg.instantiate()

# Load packages & code libraries
using DataFrames
using CSV
using Pipe
using Statistics
using CairoMakie
using QuantEcon

include("lib.jl")

const vars_ib = [:lending_facility, :deposit_facility, :loans,
    :am, :bm, :pmb, :pml, :margin_stability, :on_demand, :ON_liabs, :Term_liabs, :term_demand, :il_rate, :id_rate, :flow]

function overviews_ib(df::DataFrame)
    overviews_deficit(df)
    overviews_by_status(df)
    overviews_by_type(df)
end

function overviews_real(df::DataFrame, m::DataFrame)
    overviews_firms(df, m)
    overviews_hh(df, m)
end

function overviews_model(df::DataFrame)
    p = interest_ib(df)
    save("ib_rates.eps", p)

    p = theta_lbw(df)
    save("theta_lbw.eps", p)
end

function overviews_ib_big(df::DataFrame; baseline::Bool = false)
    df = @pipe df |> dropmissing(_, vars_ib) |>
        groupby(_, [:step, :shock, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = big_ib_plots(df)
    save("big_ib_plots.eps", p)

    p = big_ib_plots_levels(df)
    save("big_ib_plots_levels.eps", p)

    p = big_ib_plots_levels_slides(df)
    save("big_ib_plots_levels_slides.eps", p)

    if !baseline
        p = stability_ib_plots_levels(df)
        save("stability_ib_plots_levels.eps", p)

        p = stability_ib_plots(df)
        save("stability_ib_plots.eps", p)

        p = stability_ib_plots_slides(filter(r -> r.scenario == "Maturity", df))
        save("stability_ib_plots_slides_new.eps", p)
    end
end

function overviews_deficit(df)
    df = @pipe df |> dropmissing(_, vars_ib) |> filter([:status, :ib_flag] => (x, y) -> x == "deficit" && y == true, _) |>
        groupby(_, [:step, :shock, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = big_rationing_plot(df)
    save("big_rationing_plot.eps", p)

    p = ib_demand_levels(df)
    save("ib_demand_levels.eps", p)
end

function overviews_by_status(df)
    df = @pipe df |> dropmissing(_, vars_ib) |> 
        groupby(_, [:step, :shock, :status, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = flows_by_status_levels(df)
    save("flows_by_status.eps", p) 

    p = stability_by_status_levels(df)
    save("stability_by_status.eps", p)

    p = loans_by_status_levels(df)
    save("loans_by_status.eps", p)

    p = ASF_by_status_levels(df)
    save("ASF_by_status.eps", p) 

    p = RSF_by_status_levels(df)
    save("RSF_by_status.eps", p) 

    p = flows_area(df)
    save("flows_area.eps", p) 

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

    p = loans_by_type_levels(df)
    save("loans_by_type.eps", p)

    p = ASF_by_type_levels(df)
    save("ASF_by_type.eps", p) 

    p = RSF_by_type_levels(df)
    save("RSF_by_type.eps", p) 
end

function overviews_hh(df, m)
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
            overviews_ib_big(filter(:scenario => x -> x == "Baseline", adf); baseline = true)
            overviews_ib(filter(:scenario => x -> x == "Baseline", adf))
            overviews_real(filter(:scenario => x -> x == "Baseline", adf), filter(:scenario => x -> x == "Baseline", mdf))
        end

        cd(mkpath("Maturity")) do
            overviews_model(filter(:scenario => x -> x == "Maturity", mdf))
            overviews_ib_big(filter(:scenario => x -> x == "Maturity", adf); baseline = true)
            overviews_ib(filter(:scenario => x -> x == "Maturity", adf))
            overviews_real(filter(:scenario => x -> x == "Maturity", adf), filter(:scenario => x -> x == "Maturity", mdf))
        end
    end

    printstyled("Plots generated."; color = :blue)
end

create_plots()
