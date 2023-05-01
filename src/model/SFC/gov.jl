"""
Define the government's actions.
"""

"""
    prev_vars!(agent::Government) → nothing

Update the government's previous variables.
"""
function prev_vars!(agent::Government)
    agent.bills_prev = agent.bills
    agent.bonds_prev = agent.bonds
    agent.npl_prev = agent.npl
    return nothing
end

"""
    bills!(agent::Government, model) → agent.bills    

The government issues treasury bills.
"""
function bills!(agent::Government, model)
    agent.bills += agent.spending + model.ib * agent.bills_prev + model.iblr * agent.bonds_prev + (agent.npl - agent.npl_prev) - 
        agent.taxes - sum(a.profits for a in allagents(model) if a isa CentralBank) - (agent.bonds - agent.bonds_prev)

    if agent.bills < 0 
        println("negative B")
    elseif isnan(agent.bills)
        println("NaN B")
    end
    return agent.bills
end

"""
    bonds!(agent::Government, model) → agent.bonds

The government issues long-term bonds.
"""
function bonds!(agent::Government, model)
    agent.bonds = sum(a.bonds for a in allagents(model) if a isa Bank)
    return agent.bonds
end

"""
    non_performing_loans!(agent::Government, model) → agent.npl

The government absorbs non-preforming loans.
"""
function non_performing_loans!(agent::Government, model)
    agent.npl = sum(a.npl for a in allagents(model) if a isa Bank)
    return agent.npl
end

"""
    spending!(agent::Government, model) → agent.spending

The government buys consumption goods.
"""
function spending!(agent::Government, model)
    agent.spending = model.g * sum(a.prices for a in allagents(model) if a isa Firm)
    return agent.spending
end

"""
    taxes!(agent::Government, model) → agent.taxes

The government collect households' wage taxes.
"""
function taxes!(agent::Government, model)
    agent.taxes = sum(a.taxes for a in allagents(model) if a isa Household)
    return agent.taxes
end

"""
    networth!(agent::Government) → agent.networth

The government updates its networth, i.e. government debt.
"""
function networth!(agent::Government)
    agent.networth = agent.bills + agent.bonds
    return agent.networth
end

"""
    balance!(agent::Government, model) → agent.balance_current

Update the balance of the government for SFC checks.
"""
function balance!(agent::Government, model)
    agent.balance_current = (agent.bills - agent.bills_prev) + agent.taxes + sum(a.profits for a in allagents(model) if a isa CentralBank) +
        (agent.bonds - agent.bonds_prev) - agent.spending - model.ib * agent.bills_prev - model.iblr * agent.bonds_prev - 
        (agent.npl - agent.npl_prev) 
    return agent.balance_current
end

"""
    SFC!(agent::Government, model) → model

Define the government's SFC actions and update its accounting.
"""
function SFC!(agent::Government, model)
    IMS.prev_vars!(agent)
    IMS.bonds!(agent, model)
    IMS.non_performing_loans!(agent, model)
    IMS.bills!(agent, model)
    IMS.networth!(agent)
    IMS.balance!(agent, model)
    return model
end