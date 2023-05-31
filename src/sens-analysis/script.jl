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

include("lib.jl")

const vars = [:flow, :ON_liabs, :Term_liabs, :deposit_facility, :lending_facility, :margin_stability, :am, :bm, :pmb, :pml]

function interbank(df::DataFrame, param::Symbol)
    df1 = @pipe df |> dropmissing(_, vars) |> groupby(_, [:step, param]) |>
        combine(_, vars .=> mean, renamecols = false)

    p = big_ib_plots_sens(df1, param)
    save("big_ib_plots_sens.eps", p)

    p = stability_ib_plots_sens(df1, param)
    save("stability_ib_plots_sens.eps", p)

    df2 = @pipe df |> dropmissing(_, vars) |> groupby(_, [:step, :status, param]) |>
        combine(_, vars .=> mean, renamecols = false)

    p = flow(df2, param)
    save("flow.eps", p)

    p = stability(df2, param)
    save("stability.eps", p)
end

function credit(df::DataFrame, m::DataFrame, param::Symbol)
    df_hh = @pipe df |> filter(:id => x -> x >= 1 && x <= mean(m[!, :n_hh]), _) |>
        groupby(_, [:step, param]) |> 
        combine(_, [:loans] .=> mean, renamecols = false)
   
    df_firms = @pipe df |>  filter(:id => x -> x > mean(m[!, :n_hh]) && x <= mean(m[!, :n_hh]) + mean(m[!, :n_f]), _) |>
        groupby(_, [:step, param]) |> 
        combine(_, [:loans, :output] .=> mean, renamecols = false)

    p = credit_loans(df_firms, param)
    save("loans_firms_sens.eps", p)

    p = output(df_firms, param)
    save("output_sens.eps", p)

    p = credit_loans(df_hh, param; f = false)
    save("loans_hh_sens.eps", p)
end

function big_general_params(df::DataFrame, m::DataFrame, params::Vector{Symbol})
    pushfirst!(params, :step)

    df1 = @pipe df |> dropmissing(_, vars) |> 
        groupby(_, params) |>
        combine(_, vars .=> mean, renamecols = false)

    p = big_params(df1, :ON_liabs, params)
    save("big_ON_params.eps", p)

    df_firms = @pipe df |>  filter(:id => x -> x > mean(m[!, :n_hh]) && x <= mean(m[!, :n_hh]) + mean(m[!, :n_f]), _) |>
        groupby(_, params) |> 
        combine(_, :output .=> mean, renamecols = false)

    p = big_params(df_firms, :output, params)
    save("big_output_params.eps", p)
end

function load_df()
    # parameter ranges
    params_range = (
        ("0.9", "1.1", "1.3"),
        ("0.05", "0.5", "1.0"),
        ("0.03", "0.5", "1.0"),
        ("0.1", "0.5", "1.0")
    )

    df = DataFrame()
    for param in ["r", "δ",  "l", "γ", "gd"]
        if param == "r"
            for val in params_range[1]
                append!(df, CSV.File("data/sensitivity_analysis/$(param)/$(val)/df.csv"); cols = :union)
            end
        elseif param == "δ"
            for val in params_range[2]
                append!(df, CSV.File("data/sensitivity_analysis/$(param)/$(val)/df.csv"); cols = :union)
            end
        elseif param == "l"
            for val in params_range[3]
                append!(df, CSV.File("data/sensitivity_analysis/$(param)/$(val)/df.csv"); cols = :union)
            end
        else
            for val in params_range[4]
                append!(df, CSV.File("data/sensitivity_analysis/$(param)/$(val)/df.csv"); cols = :union)
            end
        end
    end

    # take model variables from Baseline scenario
    mdf = DataFrame()
    append!(mdf, CSV.File("data/shock=Missing/Baseline/mdf.csv"))

    return df, mdf
end

function load_df_mat()
    # parameter ranges
    params_range = (
        (collect(0.0:0.1:1.0))
    )

    df = DataFrame()
    for param in ["m1", "m2", "m3", "m4", "m5"]
        for val in string.(params_range)
            append!(df, CSV.File("data/sensitivity_analysis/$(param)/$(val)/df.csv"); cols = :union)
        end
    end

    # take model variables from Baseline scenario
    mdf = DataFrame()
    append!(mdf, CSV.File("data/shock=Missing/Baseline/mdf.csv"))

    return df, mdf
end

function create_sens_maturity_plots()
    df, mdf = load_df_mat()

    cd(mkpath("img/pdf/sens-analysis")) do
        for param in [:m1, :m2, :m3, :m4, :m5]
            cd(mkpath("$(param)")) do
                interbank(filter(param => x -> !ismissing(x), df), param)
                credit(filter(param => x -> !ismissing(x), df), mdf, param)
            end
        end
    end
    printstyled("Sensitivity plots for maturity parameters generated."; color = :blue)
end

create_sens_maturity_plots()

function create_sens_general_plots()
    df, mdf = load_df()

    params = [:r, :l, :δ, :γ, :gd]

    cd(mkpath("img/pdf/sens-analysis")) do
            cd(mkpath("genearal")) do
                big_general_params(df, mdf, params)
        end
    end
    popfirst!(params)
    printstyled("Sensitivity plots for general parameters generated."; color = :blue)
end

create_sens_general_plots()
