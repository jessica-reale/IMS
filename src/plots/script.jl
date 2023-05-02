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
    :margin_stability, :on_demand, :term_demand, :il_rate, :id_rate]

function overviews_model(df)
    p = ib_on_scenarios(df)
    save("ib_on_scenarios.pdf", p)  

    p = ib_term_scenarios(df)
    save("ib_term_scenarios.pdf", p)     

    p = ib_rates_scenarios(df)
    save("ib_rates_scenarios.pdf", p)    
    
    p = willingness(df)
    save("willlingness.pdf", p)    
end

function scenarios_lines(df, m)
    # ib market
    df1 = @pipe df |> dropmissing(_, vars_ib) |> groupby(_, [:step, :scenario]) |>
            combine(_, vars_ib .=> mean, renamecols = false)

    p = margin_stability(df1)
    save("margin_stability.pdf", p)

    p = am(df1)
    save("am.pdf", p)

    p = bm(df1)
    save("bm.pdf", p)

    df2 = @pipe df |>  dropmissing(_, vars_ib) |> groupby(_, [:step, :status, :scenario]) |>
            combine(_, vars_ib .=> mean, renamecols = false)

    p = pmb(filter(:status => ==("deficit"), df2))
    save("pmb.pdf", p)

    p = pml(filter(:status => ==("surplus"), df2))
    save("pml.pdf", p)

    # credit market
    df_hh = @pipe df |> filter(:id => x -> x >= 1 && x <= mean(m[!, :n_hh]), _) |>
            groupby(_, [:step, :scenario]) |> 
            combine(_, [:loans] .=> mean, renamecols = false)
   
    df_firms = @pipe df |>  filter(:id => x -> x > mean(m[!, :n_hh]) && x <= mean(m[!, :n_hh]) + mean(m[!, :n_f]), _) |>
            groupby(_, [:step, :scenario]) |> 
            combine(_, [:loans, :output] .=> mean, renamecols = false)

    p = scenarios_loans(df_firms)
    save("loans_firms_scenarios.pdf", p)

    p = scenarios_loans(df_hh; f = false)
    save("loans_hh_scenarios.pdf", p)

    p = output(df_firms)
    save("output.pdf", p)
end

function load_data()
    scenarios = ["Baseline", "Corridor", "Uncertainty", "Width"]

    adf = DataFrame()
    mdf = DataFrame()

    for scenario in scenarios
        append!(adf, CSV.File("data/$(scenario)/adf.csv"); promote = true)
        append!(mdf, CSV.File("data/$(scenario)/mdf.csv"); promote = true)
    end
    
    return adf, mdf
end

function create_plots()
    adf, mdf = load_data()

    cd(mkpath("img/pdf")) do
        cd(mkpath("overviews_model")) do
            overviews_model(mdf)
        end

        cd(mkpath("scenarios_lines")) do 
            scenarios_lines(adf, mdf)
        end
    end

    printstyled("Plots generated."; color = :blue)
end

create_plots() 