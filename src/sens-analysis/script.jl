using Pkg
Pkg.activate("src/plots")

# Load packages & code libraries
using DataFrames
using CSV
using Pipe
using Statistics
using CairoMakie
using CairoMakie.Colors
using QuantEcon
using EasyFit

include("lib.jl")

const vars_ib = [:ON_liabs, :Term_liabs, :margin_stability]

# Helper function to save LaTeX tables
function save_to_tex(filename, latex_string)
    open(filename, "w") do f
        write(f, latex_string)
    end
end

function big_general_params(df::DataFrame, m::DataFrame, params::Vector{Symbol})
    pushfirst!(params, :step)

    df1 = @pipe df |> dropmissing(_, vars_ib) |> 
        groupby(_, params) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = big_params(df1, :ON_liabs, params)
    save("big_ON_params.eps", p)

    df_firms = @pipe df |>  filter(:id => x -> x > mean(m[!, :n_hh_unique]) && x <= mean(m[!, :n_hh_unique]) + mean(m[!, :n_f_unique]), _) |>
        groupby(_, params) |> 
        combine(_, :output .=> mean, renamecols = false)

    p = big_params(df_firms, :output, params)
    save("big_output_params.eps", p)
end

function tables(df, params)
    latex_table = create_tables(df, params)
    save_to_tex("table_$(params).tex", latex_table)
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
    append!(mdf, CSV.File("data/size=100/shock=Missing/Baseline/mdf.csv"))

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

    return df
end

function load_df_threshold()
     # parameter ranges
     params_range = (
        (collect(0.01:0.04:0.1))
    )

    param = "arbitrary_threshold"

    df = DataFrame()
    for val in string.(params_range)
        append!(df, CSV.File("data/sensitivity_analysis/$(param)/$(val)/df.csv"); cols = :union)
    end

    return df
end

function create_sens_maturity_tables(adf)
    cd(mkpath("img/pdf/sens-analysis")) do
            cd(mkpath("Maturity")) do
                tables(adf, [:m1, :m4])
                tables(adf, [:m2, :m3, :m5])
            end
    end
    printstyled("Sensitivity tables for maturity parameters generated."; color = :blue)
end

function create_threshold_tables(adf)
    cd(mkpath("img/pdf/sens-analysis")) do
        cd(mkpath("Threshold")) do
            tables(adf, [:arbitrary_threshold])
        end
    end
    printstyled("Sensitivity tables for threshold parameter generated."; color = :blue)
end

function create_sens_general_plots(adf, mdf)
    params = [:r, :l, :δ, :γ, :gd]

    cd(mkpath("img/pdf/sens-analysis")) do
            cd(mkpath("General")) do
                big_general_params(adf, mdf, params)
        end
    end
    popfirst!(params)
    printstyled("Sensitivity plots for general parameters generated."; color = :blue)
end

adf, mdf = load_df()
create_sens_general_plots(adf, mdf)

adf = load_df_mat()
create_sens_maturity_tables(adf)

adf = load_df_threshold()
create_threshold_tables(adf)