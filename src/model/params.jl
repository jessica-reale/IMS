"""
Define model parameters.
"""
Base.@kwdef mutable struct Parameters
    step::Int = 0
    # number of agents
    n_f::Int = 100
    n_hh::Int = 1000
    n_bj::Int = 20
    n_bk::Int = 20
    # scenarios and shocks
    scenario::String = "Baseline"
    PDU::Float64 = 0.0
    shock_incr::Int = 300
    shock::String = "Missing"
    # initial GD/GDP ratio 
    r::Float64 = 0.9
    # model general parameters
    g::Float64 = 8750.0
    δ::Float64 = 0.05
    ϕ::Float64 = 0.25
    β::Float64 = 0.5
    σ::Int = 3
    μ::Float64 = 0.25
    v::Float64 = 0.1
    ω::Float64 = 0.2 # can be changed
    l::Float64 = 0.03
    pr::Float64 = 1.0
    τ::Float64 = 0.18
    γ::Float64 = 0.1
    ib::Float64 = 0.024
    iblr::Float64 = 0.0219
    icbt::Float64 = 0.024 # target
    icbl::Float64 = 0.02875 # lending fac
    icbd::Float64 = 0.01925 # deposit fac
    gk::Float64 = 0.1
    ρ::Float64 = 0.4
    α1::Float64 = 0.8
    α2::Float64 = 0.0 # defined at SS
    χ::Int = 5
    χ1::Float64 = 0.0085
    λ::Float64 = 2.00687
    gd::Float64 = 0.1
    # margin of stability - banks_NSFR
    m1::Float64 = 0.1
    m2::Float64 = 0.5
    m3::Float64 = 0.05
    m4::Float64 = 0.9
    m5::Float64 = 0.5
    # Interbank market
    ion::Float64 = 0.024
    iterm::Float64 = 0.024
    ion_prev::Float64 = 0.024
    iterm_prev::Float64 = 0.024
    θ::Float64 = 0.5
    LbW::Float64 = 0.5
    σib::Float64 = 0.1
    # params set in init.jl
    a0::Float64 = 0.0
end