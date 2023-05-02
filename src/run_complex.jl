using Pkg
Pkg.activate(".")
Pkg.instantiate()

# Start workers
using Distributed
addprocs()

# Set up package environment on workers
@everywhere begin
    using Pkg
    Pkg.activate(".")
end

# Load packages on master process
using Pipe
using CSV
using Random
using DataFrames
using IMS

# Load packages on workers
@everywhere begin
    using Agents
    using StatsBase
    using Distributions
    using IMS
end

# runs the model, transforms and saves data
function run_model(number_of_runs::Int = 1)
    scenarios = ("Baseline", "Corridor", "Uncertainty", "Width")

    # collect agent variables
    adata = [:type, :status, :ON_assets, :ON_liabs, :margin_stability, :am, :bm,
        :Term_assets, :Term_liabs, :loans, :loans_prev, :output, :pmb, :pml,
        :il_rate, :id_rate, :funding_costs, :lending_facility, :deposit_facility,
        :on_demand, :term_demand, :on_supply, :term_supply, :prices]
    # collect model variables
    mdata = [:n_hh, :n_f, :IBon, :IBterm, :ion, :iterm, :icbl, :icbd, :icbt, :θ, :LbW]

    for scenario in scenarios
        seeds = rand(UInt32, number_of_runs)
        
        println("Creating $number_of_runs seeded $(scenario)-scenario models and running...")

        models = [IMS.init_model(; seed, scenario = scenario) for seed in seeds]
        
        adf, mdf, _ =  ensemblerun!(models, dummystep, IMS.model_step!, 1200;
            adata, mdata, parallel = true, showprogress = true)
            
        println("Collecting data for $(scenario)-scenario...")

        # Aggregate model data over replicates
        mdf = @pipe mdf |>
            groupby(_, :step) |>
            combine(_, mdata[1:2] .=> unique, mdata[3:end] .=> mean; renamecols = false)
        mdf[!, :scenario] = fill(scenario, nrow(mdf))

        # Aggregate agent data over replicates
        adf = @pipe adf |>
            groupby(_, [:step, :id, :status]) |>
            combine(_, adata[1:2] .=> unique, adata[3:end] .=> mean; renamecols = false)
        adf[!, :scenario] = fill(scenario, nrow(adf))

        # Write data to disk
        println("Saving to disk for $(scenario)-scenario...")
        datapath = mkpath("data/$(scenario)")
        filepath = "$datapath/adf.csv"
        isfile(filepath) && rm(filepath)
        CSV.write(filepath, adf)
        filepath = "$datapath/mdf.csv"
        isfile(filepath) && rm(filepath)
        CSV.write(filepath, mdf)
        println("Finished for $(scenario) scenario.")
    end

    printstyled("Simulations finished and data saved!"; color = :blue)
    return nothing
end

Random.seed!(96100)
run_model()