module IMS

using Agents
using Pipe
using Random
using StatsBase
using Distributions
using Combinatorics

include("model/params.jl")
include("model/structs.jl")
include("model/init.jl")
include("model/utils.jl")
include("model/SFC/gov.jl")
include("model/SFC/cb.jl")
include("model/SFC/hh.jl")
include("model/SFC/firms.jl")
include("model/SFC/banks.jl")

"""
    model_step!(model) → model

Stepping function of the model: defines what happens during each simulation step.
"""
function model_step!(model)
    model.step += 1

    #begin: apply shocks
    IMS.shocks!(model)
    #end: apply shocks

    IMS.update_vars!(model)

    for id in ids_by_type(Bank, model)
        IMS.prev_vars!(model[id])
        IMS.credit_rates!(model[id], model.χ1)
        IMS.reset_vars!(model[id], model.scenario)
    end

    for id in ids_by_type(Firm, model)
        IMS.prev_vars!(model[id])
        IMS.interests_payments!(model[id], model)
        IMS.deposits!(model[id], model)
        IMS.prices!(model[id], model.ρ)
        IMS.investments!(model[id], model.gk)
        IMS.capital!(model[id], model.δ)
        IMS.output!(model[id], model.β, model.ϕ, model.σ)
        IMS.wages!(model[id], model)
        IMS.unit_costs!(model[id])
    end

    IMS.consumption_matching!(model)
    for id in ids_by_type(Household, model)
        IMS.prev_vars!(model[id])
        IMS.interests_payments!(model[id], model)
        IMS.expected_income!(model[id], model)
        IMS.consumption!(model[id], model)
        IMS.taxes!(model[id], model.τ)
    end

    IMS.hhs_matching!(model)
    for id in ids_by_type(Household, model)
        IMS.loans!(model[id], model)
        IMS.non_performing_loans!(model[id], model)
    end

    for id in ids_by_type(Government, model)
        IMS.spending!(model[id], model)
        IMS.taxes!(model[id], model)
    end
    
    IMS.firms_matching!(model)
    spending = sum(a.spending for a in allagents(model) if a isa Government) / model.n_f
    for id in ids_by_type(Firm, model)
        IMS.consumption!(model[id], model)
        IMS.sales!(model[id], model)
        IMS.rationing!(model[id], model)
        IMS.inventories!(model[id])
        IMS.profits!(model[id], spending)
        IMS.loans!(model[id], model)
        IMS.non_performing_loans!(model[id], model)
        IMS.current_balance!(model[id], spending)
        IMS.SFC!(model[id], model)
    end

    for id in ids_by_type(Bank, model)
        IMS.interests_payments!(model[id], model)
        IMS.profits!(model[id])
        IMS.current_balance!(model[id])
        IMS.portfolio!(model[id])
    end
    
    profits = sum(a.profits for a in allagents(model) if a isa Bank || a isa Firm) / model.n_hh
    for id in ids_by_type(Household, model)
        IMS.income!(model[id], profits)
        IMS.SFC!(model[id], model)
    end

    for id in ids_by_type(CentralBank, model)
        IMS.prev_vars!(model[id])
        IMS.profits!(model[id], model)
        IMS.current_balance!(model[id], model)
    end

    # begin: Interbank Market
    IMS.update_willingenss_ON!(model)
    for id in ids_by_type(Bank, model)
        IMS.update_status!(model[id])
        if model.scenario == "Maturity"
            IMS.NSFR!(model[id], model)
            IMS.borrowing_targets!(model[id], model.rng)
            IMS.lending_targets!(model[id], model.rng)
        end
        IMS.reset_after_status!(model[id])
        IMS.tot_demand!(model[id])
        IMS.tot_supply!(model[id])
    end
    IMS.ib_matching!(model)
    for id in ids_by_type(Bank, model)
        IMS.on_demand!(model[id], model)
        IMS.term_demand!(model[id], model)
        if model.scenario == "Maturity"
            IMS.on_supply!(model[id], model.LbW)
            IMS.term_supply!(model[id])
        end
        IMS.ib_on!(model[id], model)
        IMS.ib_term!(model[id], model)
        IMS.lending_facility!(model[id])
        IMS.deposit_facility!(model[id])
        IMS.funding_costs!(model[id], model.icbt, model.ion, model.iterm, model.icbl)
        IMS.bonds!(model[id])
    end
    IMS.ib_rates!(model)
    # end: Interbank Market

    for id in ids_by_type(Government, model)
        IMS.SFC!(model[id], model)
    end

    for id in ids_by_type(Bank, model)
        IMS.SFC!(model[id], model)
    end

    for id in ids_by_type(CentralBank, model)
        IMS.SFC!(model[id], model)
    end

    # SFC checks
    IMS.SFC_checks!(model)
    return model
end

""" 
    update_willingenss_ON!(model) → model.θ, model.LbW

Updates money market conditions based on interest rates.
"""
function update_willingenss_ON!(model)
    model.θ = max(0.0, min(model.a0 + (model.icbl - model.ion_prev) + (model.iterm_prev - model.ion_prev) - model.PDU, 1.0))
    model.LbW = max(0.0, min(model.a0 + (model.ion_prev - model.icbd) -  (model.iterm_prev - model.ion_prev) + model.PDU, 1.0))
    return model.θ, model.LbW
end

"""
    consumption_matching!(model) → model

Updates firms' and households' matching in the goods market.
"""
function consumption_matching!(model)
    for id in ids_by_type(Household, model)
        #Select potential partners
        potential_partners = filter(i -> model[i] isa Firm && i != model[id].belongToFirm, collect(allids(model)))[1:model.χ]
        #Select new partner with the best price
        new_partner = rand(model.rng, filter(i -> i in potential_partners && model[i].prices == minimum(model[a].prices for a in potential_partners), potential_partners))
        #Select price of the new potential partner
        inew = model[new_partner].prices
        #Pick up old partner
        old_partner = model[id].belongToFirm
        #PICK UP THE PRICE OF THE OLD PARTNER
        iold = model[old_partner].prices
        #COMPARE OLD AND NEW PRICES
        if rand(model.rng) < (1 - exp(model.λ * (inew - iold)/inew))
            #THEN SWITCH TO A NEW PARTNER
            deleteat!(model[old_partner].customers, findall(x -> x == id, model[old_partner].customers))
            model[id].belongToFirm = new_partner
            push!(model[new_partner].customers, id)
        end
    end
    return model
end

"""
    firms_matching!(model) → model

Updates firms' matching in the credit market.
"""
function firms_matching!(model)
    for id in ids_by_type(Firm, model)
        # Select potential partners
        potential_partners = filter(i -> model[i] isa Bank && i != model[id].belongToBank && model[i].type == :business, collect(allids(model)))[1:model.χ]
        # Select new partner with the best interest rate among potential partners
        new_partner = rand(model.rng, filter(i -> i in potential_partners && model[i].il_rate == minimum(model[a].il_rate for a in potential_partners), potential_partners))
        # Select interest rate of the new potential partner
        inew = model[new_partner].il_rate
        # Pick up old partner
        old_partner = model[id].belongToBank
        # PICK UP THE INTEREST OF THE OLD PARTNER
        iold = model[old_partner].il_rate
        # COMPARE OLD AND NEW INTERESTS
        if rand(model.rng) < (1 - exp(model.λ * (inew - iold)/inew))
            # THEN SWITCH TO A NEW PARTNER
            deleteat!(model[old_partner].firms_customers, findall(x -> x == id, model[old_partner].firms_customers))
            model[id].belongToBank = new_partner
            push!(model[new_partner].firms_customers, id)
        end
    end
    return model
end

"""
    hhs_matching!(model) → model

Updates households' matching in the credit market.
"""
function hhs_matching!(model)
    for id in ids_by_type(Household, model)
        # Select potential partners
        potential_partners = filter(i -> model[i] isa Bank && i != model[id].belongToBank && model[i].type == :commercial, collect(allids(model)))[1:model.χ]
        # Select new partner with the best interest rate among potential partners
        new_partner = rand(model.rng, filter(i -> i in potential_partners && model[i].il_rate == minimum(model[a].il_rate for a in potential_partners), potential_partners))
        # Select interest rate of the new potential partner
        inew = model[new_partner].il_rate
        # Pick up old partner
        old_partner = model[id].belongToBank
        # PICK UP THE INTEREST OF THE OLD PARTNER
        iold = model[old_partner].il_rate
        # COMPARE OLD AND NEW INTERESTS
        if rand(model.rng) < (1 - exp(model.λ * (inew - iold)/inew))
            # THEN SWITCH TO A NEW PARTNER
            deleteat!(model[old_partner].hh_customers, findall(x -> x == id, model[old_partner].hh_customers))
            model[id].belongToBank = new_partner
            push!(model[new_partner].hh_customers, id)
        end
    end
    return model
end

"""
    ib_matching!(model) → model

Update borrowing banks' matching.
"""
function ib_matching!(model)
    for id in ids_by_type(Bank, model)
        # end function prematurely if there are no surplus banks available
        isempty([a.id for a in allagents(model) if a isa Bank && a.status == :surplus]) && return

        if model[id].status == :deficit
            # interbank matching depends on the scenario implemented
            potential_partners = 
                if model.scenario == "Maturity"
                    # Select potential partners with the closest preferences for overnight funds
                    filter(i -> model[i] isa Bank && model[i].status == :surplus && abs((1 - model[i].margin_stability) - model[id].am) <= 1e-01, collect(allids(model)))   
                else
                    # Select potenital partners based only on interbank status and supply amount
                    filter(i -> model[i] isa Bank && model[i].status == :surplus && abs(model[i].tot_supply - model[id].tot_demand) <= 1e-06, collect(allids(model)))                          
                end
            if !isempty(potential_partners)
                # Select new partner
                new_partner = rand(model.rng, filter(i -> i in potential_partners, potential_partners))
                model[id].belongToBank = new_partner
                push!(model[new_partner].ib_customers, id)
                model[id].ib_flag = true
                model[new_partner].ib_flag = true
            end
        end
    end
    return model
end

"""
    ib_rates!(model) → model

Update interbank rates on overnight and term segments based on disequilibrium dynamics between demand and supply.
The function also checks that interest rates fall within the central bank's corridor, otherwise a warning is issued.
"""
function ib_rates!(model; tol::Float64 = 1e-03)
    if length([a.id for a in allagents(model) if a isa Bank && a.status == :deficit && !ismissing(a.belongToBank)]) > 0 && 
        length([a.id for a in allagents(model) if a isa Bank && a.status == :surplus && !isempty(a.ib_customers)]) > 0

        ON = sum(a.on_demand for a in allagents(model) if a isa Bank && a.status == :deficit && !ismissing(a.belongToBank)) - 
            sum(a.on_supply for a in allagents(model) if a isa Bank && a.status == :surplus && !isempty(a.ib_customers))
        Term = sum(a.term_demand for a in allagents(model) if a isa Bank && a.status == :deficit && !ismissing(a.belongToBank)) - 
            sum(a.term_supply for a in allagents(model) if a isa Bank && a.status == :surplus && !isempty(a.ib_customers))

        model.ion = model.icbd + ((model.icbl - model.icbd)/(1 + exp(-model.σib * ON)))
        model.iterm = model.icbd + ((model.icbl - model.icbd)/(1 + exp(-model.σib * Term)))
    else
        model.ion = model.icbt
        model.iterm = model.icbt
    end

    # check corridor
    if model.ion - model.icbl > tol || model.icbd - model.ion > tol
        @warn "Interbank ON rate outside the central bank's corridor at step $(model.step)!"
    elseif model.iterm - model.icbl > tol || model.icbd - model.iterm > tol
        @warn "Interbank Term rate outside the central bank's corridor at step $(model.step)!"
    end
    return model.ion, model.iterm
end

"""
    update_vars!(model) → model

Updates model paramaters: overnight interbank rate `model.ion` and term interbank one `model.iterm`.
"""
function update_vars!(model)
    model.ion_prev = model.ion
    model.iterm_prev = model.iterm
    return model
end

"""
    shocks!(model) → model

Defines what happens when shocks are called for: 
1) Corridor: corridor central bank's rates (`icbt`, `icbl`, `icbd`) are increased symmetrically by 50 bp every `model.shock_incr` steps;
2) Width: ceiling rate is increasead by 50 bp, altering the width every `model.shock_incr` steps;
3) Uncertainty: the degree of perceived uncertainty (`PDU`) is increased by 0.2 every `model.shock_incr` steps.
"""
function shocks!(model)
    # end prematurely if shock setting is "Missing"
    model.shock == "Missing" && return

    if model.shock == "Corridor" && iszero(model.step % model.shock_incr)
        model.icbd += 0.005
        model.icbl += 0.005
        model.icbt = (model.icbl + model.icbd) / 2.0
    elseif model.shock == "Width" && iszero(model.step % model.shock_incr)
        model.icbl += 0.005
        model.icbt = (model.icbl + model.icbd) / 2.0
    elseif model.shock == "Uncertainty" && iszero(model.step % model.shock_incr)
        model.PDU += 0.2
    end
    return model
end

end # module IMS
