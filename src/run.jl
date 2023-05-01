using Pkg
Pkg.activate(".")
Pkg.instantiate()

# Load packages 
using Agents
using StatsBase
using Distributions
using IMS

# simple way to explore the simulations
model = IMS.init_model()
