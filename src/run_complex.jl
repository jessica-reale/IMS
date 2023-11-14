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
function run_model(seeds::Vector{UInt32}, scenario::String, shock::String)
    # collect agent variables
    adata = [:type, :status, :ib_flag, :margin_stability, :flow,
        :lending_facility, :deposit_facility, :on_demand, :term_demand,
        :loans, :output, :ON_liabs, :Term_liabs,
        :on_supply, :term_supply, :ON_assets, :Term_assets]

    # collect model variables
    mdata = [:n_hh, :n_f, :ion, :iterm, :icbl, :icbd, :icbt]
   
    # set properties based on scenario and shock
    properties = (scenario = scenario,
        shock = shock)

    println("Creating $(length(seeds)) seeded $(properties.shock)-shock and $(properties.scenario)-scenario models and running...")

    # generate models
    models = [IMS.init_model(; seed, properties...) for seed in seeds]

    # run parallel models
    adf, mdf, _ =  ensemblerun!(models, dummystep, IMS.model_step!, 1200;
        adata, mdata, parallel = true, showprogress = true)
        
    println("Collecting data for $(properties.shock)-shock and $(properties.scenario)-scenario and sample size $(length(seeds))...")

    # Aggregate model data over replicates
    mdf = @pipe mdf |>
        groupby(_, :step) |>
        combine(_, mdata[1:2] .=> unique, mdata[3:end] .=> mean, mdata[3:end] .=> std; renamecols = true)
    mdf[!, :shock] = fill(properties.shock, nrow(mdf)) 
    mdf[!, :scenario] = fill(properties.scenario, nrow(mdf))
    mdf[!, :sample_size] = fill(length(seeds), nrow(mdf))

    # Aggregate agent data over replicates
    adf = @pipe adf |>
        groupby(_, [:step, :id, :status, :type, :ib_flag]) |>
        combine(_, adata[1:3] .=> unique, adata[4:end] .=> mean, adata[4:end] .=> std; renamecols = true)
    adf[!, :shock] = fill(properties.shock, nrow(adf))
    adf[!, :scenario] = fill(properties.scenario, nrow(adf))
    adf[!, :sample_size] = fill(length(seeds), nrow(adf))

    # Write data to disk
    println("Saving to disk for $(properties.shock)-shock and $(properties.scenario)-scenario and sample size $(length(seeds))...")
    datapath = mkpath("data/size=$(length(seeds))/shock=$(properties.shock)/$(properties.scenario)")
    filepath = "$datapath/adf.csv"
    isfile(filepath) && rm(filepath)
    CSV.write(filepath, adf)
    filepath = "$datapath/mdf.csv"
    isfile(filepath) && rm(filepath)
    CSV.write(filepath, mdf)
    empty!(adf)
    empty!(mdf)
    return nothing
end

const SCENARIOS = ["Baseline", "Maturity"]
const SHOCKS = ["Missing", "Corridor", "Width", "Uncertainty"]
const SAMPLE_SIZES = collect(25:25:100)

begin 
    Random.seed!(96100)
    # generate maximum seeds vector
    tot_seeds = rand(UInt32, SAMPLE_SIZES[end])
    for sample_size in SAMPLE_SIZES
        # constrain seeds vector to # runs
        seeds = tot_seeds[1:sample_size]
        # run the model for scenarios and shocks
        for scenario in SCENARIOS
            for shock in SHOCKS
                run_model(seeds, scenario, shock)
            end
        end
    end
    printstyled("Simulations finished and data saved!"; color = :blue)
end
