"""
Define base structure and properties of agent types.
"""
Base.@kwdef mutable struct Government <: AbstractAgent
    id::Int
    spending::Float64 = 0.0
    taxes::Float64 = 0.0
    bills::Float64 = 0.0
    bills_prev::Float64 = 0.0
    bonds::Float64 = 0.0
    bonds_prev::Float64 = 0.0
    npl::Float64 = 0.0
    npl_prev::Float64 = 0.0
    # SFC
    networth::Float64 = 0.0
    balance_current::Float64 = 0.0
end

Base.@kwdef mutable struct CentralBank <: AbstractAgent
    id::Int
    bills::Float64 = 0.0
    bills_prev::Float64 = 0.0
    hpm::Float64 = 0.0
    hpm_prev::Float64 = 0.0
    advances::Float64 = 0.0
    advances_prev::Float64 = 0.0
    lending_facility::Float64 = 0.0
    deposit_facility::Float64 = 0.0
    lending_facility_prev::Float64 = 0.0
    deposit_facility_prev::Float64 = 0.0
    profits::Float64 = 0.0
    # SFC
    networth::Float64 = 0.0
    balance_current::Float64 = 0.0
    balance_capital::Float64 = 0.0
end

Base.@kwdef mutable struct Firm <: AbstractAgent
    id::Int
    belongToBank::Union{Missing, Int} = missing
    customers::Vector{Int} = []
    investments::Float64 = 0.0
    nominal_investments::Float64 = 0.0
    capital::Float64 = 0.0
    capital_prev::Float64 = 0.0
    wages::Float64 = 0.0
    wages_prev::Float64 = 0.0
    consumption::Float64 = 0.0
    nominal_consumption::Float64 = 0.0
    workers::Float64 = 0.0
    prices::Float64 = 0.0
    invent::Float64 = 0.0
    invent_prev::Float64 = 0.0
    invent_exp::Float64 = 0.0
    invent_exp_prev::Float64 = 0.0
    invent_target::Float64 = 0.0
    sales::Float64 = 0.0
    sales_prev::Float64 = 0.0
    sales_exp::Float64 = 0.0
    sales_exp_prev::Float64 = 0.0
    Invent::Float64 = 0.0
    Invent_prev::Float64 = 0.0
    unit_costs::Float64 = 0.0
    unit_costs_prev::Float64 = 0.0
    output::Float64 = 0.0
    deposits::Float64 = 0.0
    deposits_prev::Float64 = 0.0
    loans::Float64 = 0.0
    loans_prev::Float64 = 0.0
    loans_interests::Float64 = 0.0
    deposits_interests::Float64 = 0.0
    profits::Float64 = 0.0
    # SFC
    networth::Float64 = 0.0
    balance_current::Float64 = 0.0
    balance_capital::Float64 = 0.0
end

Base.@kwdef mutable struct Household <: AbstractAgent
    id::Int
    belongToBank::Union{Missing, Int} = missing
    belongToFirm::Union{Missing, Int} = missing
    consumption::Float64 = 0.0
    nominal_consumption::Float64 = 0.0
    taxes::Float64 = 0.0
    wages::Float64 = 0.0
    income::Float64 = 0.0
    income_prev::Float64 = 0.0
    income_exp::Float64 = 0.0
    income_exp_prev::Float64 = 0.0
    deposits::Float64 = 0.0
    deposits_prev::Float64 = 0.0
    loans::Float64 = 0.0
    loans_prev::Float64 = 0.0
    loans_interests::Float64 = 0.0
    deposits_interests::Float64 = 0.0
    networth_prev::Float64 = 0.0
    # SFC
    networth::Float64 = 0.0
    balance_current::Float64 = 0.0
end

Base.@kwdef mutable struct Bank <: AbstractAgent
    id::Int
    type::Symbol
    status::Symbol = :neutral
    belongToBank::Union{Missing, Int} = missing
    hh_customers::Vector{Int} = []
    firms_customers::Vector{Int} = []
    ib_customers::Vector{Int} = []
    flow::Float64 = 0.0
    deposits::Float64 = 0.0
    deposits_prev::Float64 = 0.0
    bills::Float64 = 0.0
    bills_prev::Float64 = 0.0
    advances::Float64 = 0.0
    advances_prev::Float64 = 0.0
    npl::Float64 = 0.0
    npl_prev::Float64 = 0.0
    bonds::Float64 = 0.0
    bonds_prev::Float64 = 0.0
    hpm::Float64 = 0.0
    hpm_prev::Float64 = 0.0
    loans::Float64 = 0.0
    loans_prev::Float64 = 0.0
    funding_costs::Float64 = 0.0
    funding_costs_prev::Float64 = 0.0
    il_rate::Float64 = 0.0
    il_rate_prev::Float64 = 0.0
    id_rate::Float64 = 0.0
    id_rate_prev::Float64 = 0.0
    profits::Float64 = 0.0
    lending_facility::Float64 = 0.0
    lending_facility_prev::Float64 = 0.0
    deposit_facility::Float64 = 0.0
    deposit_facility_prev::Float64 = 0.0
    loans_interests::Float64 = 0.0
    deposits_interests::Float64 = 0.0
    bills_interests::Float64 = 0.0
    bonds_interests::Float64 = 0.0
    hpm_interests::Float64 = 0.0
    advances_interests::Float64 = 0.0
    lending_facility_interests::Float64 = 0.0
    deposit_facility_interests::Float64 = 0.0
    # NSFR
    tot_assets::Float64 = 0.0
    tot_liabilities::Float64 = 0.0
    am::Float64 = 0.0
    bm::Float64 = 0.0
    margin_stability::Float64 = 0.0
    actual_lend_ratio::Float64 = 0.0
    target_lend_ratio::Float64 = 0.0
    actual_borr_ratio::Float64 = 0.0
    target_borr_ratio::Float64 = 0.0
    # ib 
    tot_demand::Float64 = 0.0
    on_demand::Float64 = 0.0
    term_demand::Float64 = 0.0
    tot_supply::Float64 = 0.0
    on_supply::Float64 = 0.0
    term_supply::Float64 = 0.0
    ON_assets::Float64 = 0.0
    ON_assets_prev::Float64 = 0.0
    ON_liabs::Float64 = 0.0
    ON_liabs_prev::Float64 = 0.0
    Term_assets::Float64 = 0.0
    Term_assets_prev::Float64 = 0.0
    Term_liabs::Float64 = 0.0
    Term_liabs_prev::Float64 = 0.0
    pmb::Float64 = 1.0
    pml::Float64 = 1.0
    # SFC
    networth::Float64 = 0.0
    balance_current::Float64 = 0.0
    balance_capital::Float64 = 0.0
end