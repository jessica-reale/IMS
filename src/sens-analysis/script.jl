using Pkg

# Load packages & code libraries
using DataFrames
using CSV
using Pipe
using Statistics
using CairoMakie
using QuantEcon

include("lib.jl")

function interbank(df::DataFrame, param::Symbol)
    vars = [:pmb, :pml]

    # take only bank agents
    df = @pipe df |> dropmissing(_, vars) |> groupby(_, [:step, :status, param]) |> 
        combine(_, vars .=> mean, renamecols = false) |> filter(row -> all(x -> !(x isa Number && isnan(x)), row), _)
    
    p = pmb(filter(:status => x -> x == "deficit", df), param)
    save("pmb.pdf", p)

    p = pml(filter(:status => x -> x == "surplus", df), param)
    save("pml.pdf", p)

end

function credit(df::DataFrame, m::DataFrame, param::Symbol)
    df_hh = @pipe df |> filter(:id => x -> x >= 1 && x <= mean(m[!, :n_hh]), _) |>
        groupby(_, [:step, param]) |> 
        combine(_, [:loans] .=> mean, renamecols = false)
   
    df_firms = @pipe df |>  filter(:id => x -> x > mean(m[!, :n_hh]) && x <= mean(m[!, :n_hh]) + mean(m[!, :n_f]), _) |>
        groupby(_, [:step, param]) |> 
        combine(_, [:loans, :output] .=> mean, renamecols = false)

    p = credit_loans(df_firms, param)
    save("loans_firms_sens.pdf", p)

    p = output(df_firms, param)
    save("output_sens.pdf", p)

    p = credit_loans(df_hh, param; f = false)
    save("loans_hh_sens.pdf", p)
end

function load_data()
    # parameter names as strings
    params_strings = ["r", "δ"]
    # parameter ranges
    params_range = [
        "0.9", "1.1", "1.3",
        "0.05", "0.5", "1.0"
        ]

    df = DataFrame()
    for param in params_strings
        if param == "r"
            for val in params_range[1:3]
                append!(df, CSV.File("data/sensitivity_analysis/$(param)/$(val)/df.csv"); cols = :union)
            end
        else
            for val in params_range[4:end]
                append!(df, CSV.File("data/sensitivity_analysis/$(param)/$(val)/df.csv"); cols = :union)
            end
        end
    end

    # take model variables from Baseline scenario
    mdf = DataFrame()
    append!(mdf, CSV.File("data/shock=Missing/Low/mdf.csv"))

    return df, mdf
end

function create_sens_plots()
    df, mdf = load_data()

    # parameter names as symbols
    param_symbols = [:r, :δ]

    cd(mkpath("img/pdf/sens-analysis")) do
        for param in param_symbols
            cd(mkpath("$(param)")) do
                interbank(filter(param => x -> !ismissing(x), df), param)
                credit(filter(param => x -> !ismissing(x), df), mdf, param)
            end
        end
    end
    printstyled("Sensitivity plots generated."; color = :blue)
end

create_sens_plots()
 