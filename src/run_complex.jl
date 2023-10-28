using Pkg
Pkg.activate(".")
Pkg.instantiate()

# Start workers
using Distributed
addprocs(5)    

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
function run_model(sample_size::Int, scenario::String, shock::String)
    # collect agent variables
    adata = [:type, :status, :ib_flag, :margin_stability, :am, :bm, :flow,
        :lending_facility, :deposit_facility, :on_demand, :term_demand,
        :loans, :output, :pmb, :pml, :il_rate, :id_rate, :ON_liabs, :Term_liabs,
        :consumption, :on_supply, :term_supply]

    # collect model variables
    mdata = [:n_hh, :n_f, :ion, :iterm, :icbl, :icbd, :icbt, :θ, :LbW, :g]
    # generate seeds according to sample size, i.e. number of parallel runs
    seeds = rand(UInt32, sample_size)
    # set properties based on scenario and shock
    properties = (scenario = scenario,
        shock = shock) 

    println("Creating $(sample_size) seeded $(properties.shock)-shock and $(properties.scenario)-scenario models and running...")
    # generate models
    models = [IMS.init_model(; seed, properties...) for seed in seeds]
    # run parallel models
    adf, mdf, _ =  ensemblerun!(models, dummystep, IMS.model_step!, 1200;
        adata, mdata, parallel = true, showprogress = true)
        
    println("Collecting data for $(properties.shock)-shock and $(properties.scenario)-scenario and sample size $(sample_size)...")

    # Aggregate model data over replicates
    mdf = @pipe mdf |>
        groupby(_, :step) |>
        combine(_, mdata[1:2] .=> unique, mdata[3:end] .=> mean, mdata[3:end] .=> std; renamecols = true)
    mdf[!, :shock] = fill(properties.shock, nrow(mdf))
    mdf[!, :scenario] = fill(properties.scenario, nrow(mdf))
    mdf[!, :sample_size] = fill(sample_size, nrow(mdf))

    # Aggregate agent data over replicates
    adf = @pipe adf |>
        groupby(_, [:step, :id, :status, :type, :ib_flag]) |>
        combine(_, adata[1:3] .=> unique, adata[4:end] .=> mean, adata[4:end] .=> std; renamecols = true)
    adf[!, :shock] = fill(properties.shock, nrow(adf))
    adf[!, :scenario] = fill(properties.scenario, nrow(adf))
    adf[!, :sample_size] = fill(sample_size, nrow(adf))

    # Write data to disk
    println("Saving to disk for $(properties.shock)-shock and $(properties.scenario)-scenario and sample size $(sample_size)...")
    datapath = mkpath("data/size=$(sample_size)/shock=$(properties.shock)/$(properties.scenario)")
    filepath = "$datapath/adf.csv"
    isfile(filepath) && rm(filepath)
    CSV.write(filepath, adf)
    filepath = "$datapath/mdf.csv"
    isfile(filepath) && rm(filepath)
    CSV.write(filepath, mdf)
    println("Finished for $(properties.shock) shock and $(properties.scenario) scenario and sample size $(sample_size).")
    empty!(adf)
    empty!(mdf)
    return nothing
end

const SCENARIOS = ["Baseline", "Maturity"]
const SHOCKS = ["Missing", "Corridor", "Width", "Uncertainty"]
const SAMPLE_SIZE = collect(25:25:100)

begin 
    Random.seed!(96100)
    for scenario in SCENARIOS, shock in SHOCKS, sample_size in SAMPLE_SIZE  
        run_model(sample_size, scenario, shock)
    end
    printstyled("Simulations finished and data saved!"; color = :blue)
end
