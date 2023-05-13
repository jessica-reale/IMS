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
function run_model(number_of_runs::Int = 50)
    scenarios = ("Baseline", "Maturity")
    shocks = ("Missing", "Corridor" , "Width", "Uncertainty")

    # collect agent variables
    adata = [:type, :status, :ON_assets, :ON_liabs, :margin_stability, :am, :bm,
        :Term_assets, :Term_liabs, :loans, :loans_prev, :output, :pmb, :pml, :tot_assets, 
        :tot_liabilities, :il_rate, :id_rate, :funding_costs, :lending_facility, :deposit_facility,
        :on_demand, :term_demand, :on_supply, :term_supply, :prices]
    # collect model variables
    mdata = [:n_hh, :n_f, :ion, :iterm, :icbl, :icbd, :icbt, :θ, :LbW]

    for scenario in scenarios
        seeds = rand(UInt32, number_of_runs)
        
        for shock in shocks 
            properties = (scenario = scenario,
                shock = shock) 
            
            println("Creating $number_of_runs seeded $(properties.shock)-shock and $(properties.scenario)-scenario models and running...")

            models = [IMS.init_model(; seed, properties...) for seed in seeds]
            
            adf, mdf, _ =  ensemblerun!(models, dummystep, IMS.model_step!, 1200;
                adata, mdata, parallel = true, showprogress = true)
                
            println("Collecting data for $(properties.shock)-shock and $(properties.scenario)-scenario...")

            # Aggregate model data over replicates
            mdf = @pipe mdf |>
                groupby(_, :step) |>
                combine(_, mdata[1:2] .=> unique, mdata[3:end] .=> mean; renamecols = false)
            mdf[!, :shock] = fill(properties.shock, nrow(mdf))
            mdf[!, :scenario] = fill(properties.scenario, nrow(mdf))

            # Aggregate agent data over replicates
            adf = @pipe adf |>
                groupby(_, [:step, :id, :status, :type]) |>
                combine(_, adata[1:2] .=> unique, adata[3:end] .=> mean; renamecols = false)
            adf[!, :shock] = fill(properties.shock, nrow(adf))
            adf[!, :scenario] = fill(properties.scenario, nrow(adf))

            # Write data to disk
            println("Saving to disk for $(properties.shock)-shock and $(properties.scenario)-scenario...")
            datapath = mkpath("data/shock=$(properties.shock)/$(properties.scenario)")
            filepath = "$datapath/adf.csv"
            isfile(filepath) && rm(filepath)
            CSV.write(filepath, adf)
            filepath = "$datapath/mdf.csv"
            isfile(filepath) && rm(filepath)
            CSV.write(filepath, mdf)
            println("Finished for $(properties.shock) shock and $(properties.scenario) scenario.")
        end
    end

    printstyled("Simulations finished and data saved!"; color = :blue)
    return nothing
end

Random.seed!(96100)
run_model()