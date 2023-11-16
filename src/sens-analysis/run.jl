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

# runs the sensitivity analysis for the parameters of interests, transforms and collects datas
function run_sens(seeds::Vector{UInt32}, param::Symbol, param_range::Vector{Float64}; scenario::String = "Baseline")
    # collect agent variables
    adata = [:ib_flag, :status, :margin_stability, :output, :ON_liabs, :Term_liabs]

    for x in param_range
        # Setup model properties
        properties = (
            param => x,
            scenario = scenario,
        )

        println("Running parameter scans for $(param) at $(x)...")
        
        models = [IMS.init_model(; seed, properties...) for seed in seeds]

        # run parallel models
        adf, _ =  ensemblerun!(models, dummystep, IMS.model_step!, 1200;
            adata, parallel = true, showprogress = true)

        println("Collecting data for $(param) at $(x)...")

        # Aggregate agent data
        adf = @pipe adf |>
            groupby(_, [:step, :id, :ib_flag, :status]) |>
            combine(_, adata[1:2] .=> unique, adata[3:end] .=> mean; renamecols = false)
        adf[!, param] .= x

        # Write data to disk
        println("Saving to disk for $(param) at $(x)...")
        datapath = mkpath("data/sensitivity_analysis/$(param)/$(x)")
        filepath = "$datapath/df.csv"
        isfile(filepath) && rm(filepath)
        CSV.write(filepath, adf)
        empty!(adf)
    end
    return nothing
end

function run(seeds::Vector{UInt32})
    # general params
    #= run_sens(seeds, :r, [0.9, 1.1, 1.3])
    run_sens(seeds, :δ, [0.05, 0.5, 1.0])
    run_sens(seeds, :l , [0.03, 0.5, 1.0])
    run_sens(seeds, :γ, [0.1, 0.5, 1.0])
    run_sens(seeds, :gd, [0.1, 0.5, 1.0]) =#
    # NSFR params
    #run_sens(seeds, :m1, collect(0.0:0.1:1.0); scenario = "Maturity")
    #run_sens(seeds, :m2, collect(0.0:0.1:1.0); scenario = "Maturity")
    run_sens(seeds, :m3, collect(0.0:0.1:1.0); scenario = "Maturity")
    run_sens(seeds, :m4, collect(0.0:0.1:1.0); scenario = "Maturity")
    run_sens(seeds, :m5, collect(0.0:0.1:1.0); scenario = "Maturity")
   
    printstyled("Paramascan and data collection finished."; color = :blue)
    return nothing
end

begin 
    Random.seed!(96100)
    seeds = rand(UInt32, 100)
    run(seeds)
end
