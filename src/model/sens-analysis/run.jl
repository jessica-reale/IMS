using Pkg
Pkg.activate(".")
Pkg.instantiate()

# Load packages on master process
using Pipe
using CSV
using DataFrames
using Agents
using Random
using StatsBase
using Distributions
using IMS

# runs the sensitivity analysis for the parameters of interests, transforms and collects datas
function run_sens(param::Symbol, param_range::Vector{Float64})
    # collect agent variables
    adata = [:type, :status, :ON_assets, :ON_liabs, :margin_stability, :am, :bm,
        :Term_assets, :Term_liabs, :loans, :loans_prev, :output, :pmb, :pml,
        :il_rate, :id_rate, :funding_costs, :lending_facility, :deposit_facility,
        :on_demand, :term_demand, :on_supply, :term_supply, :prices]

    for x in param_range
        # Setup model properties
        properties = Dict(
            param => x,
        )

        println("Running parameter scans for $(param) at $(x)...")

        df, _ = paramscan(properties, IMS.init_model;
                adata = adata, model_step! = IMS.model_step!, n = 1200,
                include_constants = true)

        println("Collecting data for $(param) at $(x)...")

        # Aggregate agent data
        df = @pipe df |>
            groupby(_, [param, :step, :id, :status]) |>
            combine(_, adata[1:2] .=> unique, adata[3:end] .=> mean; renamecols = false)
    
        # Write data to disk
        println("Saving to disk for $(param) at $(x)...")
        datapath = mkpath("data/sensitivity_analysis/$(param)/$(x)")
        filepath = "$datapath/df.csv"
        isfile(filepath) && rm(filepath)
        CSV.write(filepath, df)
    end
    return nothing
end

function run()
    run_sens(:r, [0.9, 1.1, 1.3])
    run_sens(:a0, [0.1, 0.5, 1.0])
    run_sens(:a1, [0.2, 0.5, 1.0])
    run_sens(:a2, [0.2, 0.5, 1.0])
    run_sens(:a3, [0.4, 0.5, 1.0])
    run_sens(:δ, [0.05, 0.5, 1.0])

    printstyled("Paramascan and data collection finished."; color = :blue)
    return nothing
end

Random.seed!(96100)
run()