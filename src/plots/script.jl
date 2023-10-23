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
using LaTeXStrings

include("lib.jl")

const vars_ib = [:lending_facility, :deposit_facility, :loans,
    :am, :bm, :pmb, :pml, :margin_stability, :on_demand, :ON_liabs, :Term_liabs, :term_demand, :il_rate, :id_rate, :flow]

function overviews_ib(df::DataFrame)
    overviews_deficit(df)
    overviews_by_status(df)
end

function overviews_model(df::DataFrame)
    p = generate_plots(df, [:ion, :iterm], missing, missing, [L"\text{ON rate}", L"\text{Term rate}"])
    save("ib_rates.eps", p)
end

function overviews_ib_big(df::DataFrame; baseline::Bool = false)
    df = @pipe df |> dropmissing(_, vars_ib) |>
        groupby(_, [:step, :shock, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = generate_plots(df, [:Term_liabs, :ON_liabs, :lending_facility, :deposit_facility], missing,
        [L"\text{Term segment}", L"\text{Overnight segment}", L"\text{Lending facility}", L"\text{Deposit facility}"], missing; by_vars = true)
    save("big_ib_plots_levels.eps", p)

    if !baseline
        p = generate_plots(df, [:margin_stability, :am, :bm, :pmb, :pml], missing, [L"\text{Margin of stability}", L"\text{ASF} a_{m}", L"\text{RSF} b_{m}",
        L"\Pi^{b}", L"\Pi^{l}"], missing; by_vars = true)
        save("stability_ib_plots_levels.eps", p)
    end
end

function overviews_deficit(df)
    df = @pipe df |> dropmissing(_, vars_ib) |> filter([:status, :ib_flag] => (x, y) -> x == "deficit" && y == true, _) |>
        groupby(_, [:step, :shock, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = generate_plots(df, [:ON_liabs, :Term_liabs],  [:on_demand, :term_demand], [L"\text{Overnight rationing}", L"\text{Term rationing}"], missing; rationing = true)
    save("big_rationing_plot.eps", p)

    p = generate_plots(df, [:on_demand, :term_demand], missing, [L"\text{Overnigth demand}", L"\text{Term demand}"], missing; by_vars = true )
    save("ib_demand_levels.eps", p)
end

function overviews_by_status(df)
    df = @pipe df |> dropmissing(_, vars_ib) |> 
        groupby(_, [:step, :shock, :status, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = generate_plots(df, [:margin_stability], missing, missing, missing; status = true)
    save("stability_by_status.eps", p)

    p = generate_plots(df, [:loans], missing, missing, missing; status = true)
    save("loans_by_status.eps", p)

    p = generate_plots(df, [:flow], missing, missing, missing; area = true)
    save("flows_area.eps", p)
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
        end

        cd(mkpath("Maturity")) do
            overviews_model(filter(:scenario => x -> x == "Maturity", mdf))
            overviews_ib_big(filter(:scenario => x -> x == "Maturity", adf); baseline = true)
            overviews_ib(filter(:scenario => x -> x == "Maturity", adf))
        end
    end

    printstyled("Plots generated."; color = :blue)
end

create_plots()
