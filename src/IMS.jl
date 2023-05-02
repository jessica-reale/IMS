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

function model_step!(model)
    model.step += 1

    #begin: apply shocks
    if model.scenario == "Corridor" && model.step == 200
        model.icbd += 0.005
        model.icbl += 0.005
        model.icbt = (model.icbl + model.icbd) / 2.0
    elseif model.scenario == "Uncertainty" && model.step == 200
        model.PDU += 0.3
    elseif model.scenario == "Width" && model.step == 200
        model.icbl += 0.005
        model.icbt = (model.icbl + model.icbd) / 2.0
    end
    #end: apply shocks

    IMS.update_vars!(model)

    for id in ids_by_type(Bank, model)
        IMS.prev_vars!(model[id])
        IMS.NSFR!(model[id], model)
        IMS.credit_rates!(model[id], model.χ1)
        IMS.reset_vars!(model[id])
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
        IMS.inventories!(model[id], model.g)
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
        IMS.update_status!(model[id]) # updates IB status
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
    IMS.ib_matching!(model)
    IMS.update_willingenss_ON!(model)
    for id in ids_by_type(Bank, model)
        IMS.update_ib_demand_supply!(model[id], model)
        IMS.ib_stocks!(model[id], model)
        IMS.lending_facility!(model[id])
        IMS.deposit_facility!(model[id])
        IMS.funding_costs!(model[id], model.icbt, model.ion, model.iterm, model.icbl)
        IMS.SFC!(model[id], model)
    end
    IMS.ib_stocks!(model)
    IMS.ib_rates!(model)
    # end: Interbank Market
    
    for id in ids_by_type(Government, model)
        IMS.SFC!(model[id], model)
    end

    for id in ids_by_type(CentralBank, model)
        IMS.SFC!(model[id], model)
    end

    IMS.SFC_checks!(model) # check for Stock-Flow consistency 
    return model
end

""" 
    update_willingenss_ON!(model) → model.θ, model.LbW

Updates money market conditions based on interest rates.
"""
function update_willingenss_ON!(model)
    model.θ = max(0.0, min(model.a0 + model.a1 * (model.icbl - model.ion_prev) + model.a2 * (model.iterm_prev - model.ion_prev) - model.a3 * (model.icbl - model.iterm_prev) - model.a4 * model.PDU, 1.0))
    model.LbW = max(0.0, min(model.a0 + model.a1 * (model.ion_prev - model.icbd) -  model.a2 * (model.iterm_prev - model.ion_prev) - model.a3 * (model.iterm_prev - model.icbd) + model.a4 * model.PDU, 1.0))
    return model.θ, model.LbW
end

"""
    firms_matching!(model) → model
Updates firms' matching in the credit market.
"""
function firms_matching!(model)
    for id in ids_by_type(Firm, model)
        #Select potential partners
        potential_partners = filter(i -> model[i] isa Bank && i != model[id].belongToBank && model[i].type == :business, collect(allids(model)))[1:model.χ]
        #Select new partner with the best interest rate among potential partners
        new_partner = rand(model.rng, filter(i -> i in potential_partners && model[i].il_rate == minimum(model[a].il_rate for a in potential_partners), potential_partners))
        #Select interest rate of the new potential partner
        inew = model[new_partner].il_rate
        #Pick up old partner
        old_partner = model[id].belongToBank
        #PICK UP THE INTEREST OF THE OLD PARTNER
        iold = model[old_partner].il_rate
        #COMPARE OLD AND NEW INTERESTS
        if rand(model.rng) < (1 - exp(model.λ * (inew - iold)/inew))
            #THEN SWITCH TO A NEW PARTNER
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
        #Select potential partners
        potential_partners = filter(i -> model[i] isa Bank && i != model[id].belongToBank && model[i].type == :commercial, collect(allids(model)))[1:model.χ]
        #Select new partner with the best interest rate among potential partners
        new_partner = rand(model.rng, filter(i -> i in potential_partners && model[i].il_rate == minimum(model[a].il_rate for a in potential_partners), potential_partners))
        #Select interest rate of the new potential partner
        inew = model[new_partner].il_rate
        #Pick up old partner
        old_partner = model[id].belongToBank
        #PICK UP THE INTEREST OF THE OLD PARTNER
        iold = model[old_partner].il_rate
        #COMPARE OLD AND NEW INTERESTS
        if rand(model.rng) < (1 - exp(model.λ * (inew - iold)/inew))
            #THEN SWITCH TO A NEW PARTNER
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
            #Select potential partners with the closest preferences for overnight funds
            potential_partners = filter(i -> model[i] isa Bank && model[i].status == :surplus && abs(model[i].pml - model[id].pmb) <= 1e-01, collect(allids(model)))
            if !isempty(potential_partners) #&& rand(model.rng, Bool)
                #Select new partner
                new_partner = rand(model.rng, filter(i -> i in potential_partners, potential_partners))
                model[id].belongToBank = new_partner
                push!(model[new_partner].ib_customers, id)
            end
        end
    end
    return model
end

"""
    ib_stocks!(model) → model.IBon, model.IBterm

Updates interbank market stocks.
"""
function ib_stocks!(model)
    if length([a.id for a in allagents(model) if a isa Bank && a.status == :deficit && !ismissing(a.belongToBank)]) > 0 && 
        length([a.id for a in allagents(model) if a isa Bank && a.status == :surplus && !isempty(a.ib_customers)]) > 0

        if sum(a.on_demand for a in allagents(model) if a isa Bank && a.status == :deficit) > sum(a.on_supply for a in allagents(model) if a isa Bank && a.status == :surplus)
            model.IBon = sum(a.on_supply for a in allagents(model) if a isa Bank && a.status == :surplus)
        elseif sum(a.on_demand for a in allagents(model) if a isa Bank && a.status == :deficit) <= sum(a.on_supply for a in allagents(model) if a isa Bank && a.status == :surplus)
            model.IBon = sum(a.on_demand for a in allagents(model) if a isa Bank && a.status == :deficit)
        end

        if sum(a.term_demand for a in allagents(model) if a isa Bank && a.status == :deficit) > sum(a.term_supply for a in allagents(model) if a isa Bank && a.status == :surplus)
            model.IBterm = sum(a.term_supply for a in allagents(model) if a isa Bank && a.status == :surplus)
        elseif sum(a.term_demand for a in allagents(model) if a isa Bank && a.status == :deficit) <= sum(a.term_supply for a in allagents(model) if a isa Bank && a.status == :surplus)
            model.IBterm = sum(a.term_demand for a in allagents(model) if a isa Bank && a.status == :deficit)
        end
    end
    return model.IBon, model.IBterm
end


"""
    ib_rates!(model) → model

Update interbank rates on overnight and term segments based on disequilibrium dynamics between demand and supply.
The function also checks that interest rates fall within the central bank's corridor, otherwise a warning is issued.
"""
function ib_rates!(model)
    if length([a.id for a in allagents(model) if a isa Bank && a.status == :deficit && !ismissing(a.belongToBank)]) > 0 && 
        length([a.id for a in allagents(model) if a isa Bank && a.status == :surplus && !isempty(a.ib_customers)]) > 0
 
        ON = sum(a.on_demand for a in allagents(model) if a isa Bank && a.status == :deficit) - 
            sum(a.on_supply for a in allagents(model) if a isa Bank && a.status == :surplus)
        Term = sum(a.term_demand for a in allagents(model) if a isa Bank && a.status == :deficit) - 
            sum(a.term_supply for a in allagents(model) if a isa Bank && a.status == :surplus)

        model.ion = model.icbd + ((model.icbl - model.icbd)/(1 + exp(-model.σib * ON)))
        model.iterm = model.icbd + ((model.icbl - model.icbd)/(1 + exp(-model.σib * Term)))
    end

    # check corridor
    if model.ion > model.icbl || model.ion < model.icbd
        @warn "Interbank ON rate outside the central bank's corridor!"
    elseif model.iterm > model.icbl || model.iterm < model.icbd
        @warn "Interbank Term rate outside the central bank's corridor!"
    end
    return model.ion, model.iterm
end

function update_vars!(model)
    model.ion_prev = model.ion
    model.iterm_prev = model.iterm
    return model
end

end # module IMS
