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
    :margin_stability, :on_supply, :term_supply, :on_demand, :term_demand, :il_rate, :id_rate, :tot_assets, :tot_liabilities]

function overviews_model(df)
    p = ib_rates_scenarios(df)
    save("ib_rates_scenarios.pdf", p)
    
    p = willingness(df)
    save("willlingness.pdf", p)
end

function scenarios_lines(df, m)
    # ib market
    df1 = @pipe df |> dropmissing(_, vars_ib) |> groupby(_, [:step, :scenario]) |>
            combine(_, vars_ib .=> mean, renamecols = false) |> filter(row -> all(x -> !(x isa Number && isnan(x)), row), _)

    p = assets(df1)
    save("total_assets.pdf", p)

    p = liabilities(df1)
    save("total_liabilities.pdf", p)

    p = ib_on_scenarios(df1)
    save("ib_on_scenarios.pdf", p)  

    p = ib_term_scenarios(df1)
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
    
    df2 = @pipe df |> dropmissing(_, vars_ib) |> groupby(_, [:step, :status, :scenario]) |>
            combine(_, vars_ib .=> mean, renamecols = false) |> filter(row -> all(x -> !(x isa Number && isnan(x)), row), _)

    p = ib_on_rationing(filter(:status => x -> x == "deficit", df2))
    save("ib_on_rationing.pdf", p)  

    p = ib_term_rationing(filter(:status => x -> x == "deficit", df2))
    save("ib_term_rationing.pdf", p) 

    p = margin_stability(filter(:status => x -> x == "deficit", df2))
    save("margin_stability_deficit.pdf", p)

    p = am(filter(:status => x -> x == "deficit", df2))
    save("am_deficit.pdf", p)

    p = bm(filter(:status => x -> x == "deficit", df2))
    save("bm_deficit.pdf", p)

    p = margin_stability(filter(:status => x -> x == "surplus", df2))
    save("margin_stability_surplus.pdf", p)

    p = am(filter(:status => x -> x == "surplus", df2))
    save("am_surplus.pdf", p)

    p = bm(filter(:status => x -> x == "surplus", df2))
    save("bm_surplus.pdf", p)

    # credit market
    df_hh = @pipe df |> filter(:id => x -> x >= 1 && x <= mean(m[!, :n_hh]), _) |>
            groupby(_, [:step, :scenario]) |> 
            combine(_, [:loans] .=> mean, renamecols = false)
   
    df_firms = @pipe df |>  filter(:id => x -> x > mean(m[!, :n_hh]) && x <= mean(m[!, :n_hh]) + mean(m[!, :n_f]), _) |>
            groupby(_, [:step, :scenario]) |> 
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
    scenarios = ["Low", "High"]
    shocks = ["Missing", "Corridor", "Width"]

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
        cd(mkpath("Missing-shock")) do
            cd(mkpath("overviews_model")) do
                overviews_model(filter(:shock => x -> x == "Missing", mdf))
            end

            cd(mkpath("scenarios_lines")) do 
                scenarios_lines(filter(:shock => x -> x == "Missing", adf), filter(:shock => x -> x == "Missing", mdf))
            end
        end

        cd(mkpath("Corridor-shock")) do
            cd(mkpath("overviews_model")) do
                overviews_model(filter(:shock => x -> x == "Missing", mdf))
            end

            cd(mkpath("scenarios_lines")) do 
                scenarios_lines(filter(:shock => x -> x == "Corridor", adf), filter(:shock => x -> x == "Corridor", mdf))
            end
        end

        cd(mkpath("Width-shock")) do
            cd(mkpath("overviews_model")) do
                overviews_model(filter(:shock => x -> x == "Missing", mdf))
            end

            cd(mkpath("scenarios_lines")) do 
                scenarios_lines(filter(:shock => x -> x == "Width", adf), filter(:shock => x -> x == "Width", mdf))
            end
        end
    end

    printstyled("Plots generated."; color = :blue)
end

create_plots()