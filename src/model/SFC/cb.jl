"""
Define the central bank's actions.
"""

"""
    prev_vars!(agent::CentralBank) → nothing

Update the central bank's previous variables.
"""
function prev_vars!(agent::CentralBank)
    agent.bills_prev = agent.bills
    agent.hpm_prev = agent.hpm
    agent.advances_prev = agent.advances
    agent.lending_facility_prev = agent.lending_facility
    agent.deposit_facility_prev = agent.deposit_facility
    return nothing
end

"""
    bills!(agent::CentralBank, gov_bills, bank_bills) → agent.bills

The central bank buys government bills to clear the bills market.
"""
function bills!(agent::CentralBank, gov_bills, bank_bills) # id
    agent.bills = gov_bills - bank_bills
    return agent.bills
end

"""
    hpm!(agent::CentralBank, tot_hpm) → agent.hpm

The central bank issues reserves on demand.
"""
function hpm!(agent::CentralBank, tot_hpm)
    agent.hpm = tot_hpm
    return agent.hpm
end

"""
    advances!(agent::CentralBank, tot_advances) → agent.advances

The central bank issues advances on demand.
"""
function advances!(agent::CentralBank, tot_advances)
    agent.advances = tot_advances
    return agent.advances
end

"""
    facilities!(agent::CentralBank, tot_l_fac, tot_d_fac) → agent.lending_facility, agent.deposit_facility

The central bank allows banks to access its standing facilitites.
"""
function facilities!(agent::CentralBank, tot_l_fac, tot_d_fac)
    agent.lending_facility = tot_l_fac
    agent.deposit_facility = tot_d_fac
    return agent.lending_facility, agent.deposit_facility
end

"""
    profits!(agent::CentralBank, model) → agent.profits

The central bank computes its profits, which are then distributed to the government.
"""
function profits!(agent::CentralBank, model)
    agent.profits = model.ib * agent.bills_prev + model.icbt * agent.advances_prev - model.icbt * agent.hpm_prev + model.icbl * agent.lending_facility_prev - 
        model.icbd * agent.deposit_facility_prev
    return agent.profits
end

"""
    networth!(agent::CentralBank) → agent.networth

The central bank updates its networth.
"""
function networth!(agent::CentralBank)
    agent.networth = agent.bills + agent.advances - agent.hpm + agent.lending_facility - agent.deposit_facility
    return agent.networth
end

"""
    current_balance!(agent::CentralBank, model) → agent.balance_current

Update the central bank's current balances for SFC checks.
"""
function current_balance!(agent::CentralBank, model)
    agent.balance_current = model.ib * agent.bills_prev + model.icbt * agent.advances_prev - model.icbt * agent.hpm_prev - agent.profits + 
        model.icbl * agent.lending_facility_prev - model.icbd * agent.deposit_facility_prev
    return agent.balance_current
end

"""
    capital_balance!(agent::CentralBank) → agent.balance_capital

Update the central bank's capital balances for SFC checks.
"""
function capital_balance!(agent::CentralBank)
    agent.balance_capital = agent.hpm + agent.deposit_facility - agent.advances - agent.bills - agent.lending_facility # hiddden equation
    return agent.balance_capital
end

"""
    SFC!(agent::CentralBank, model) →  model

Define the central bank's SFC actions and update its accounting.
"""
function SFC!(agent::CentralBank, model)
    tot_hpm = sum(a.hpm for a in allagents(model) if a isa Bank)
    IMS.hpm!(agent, tot_hpm)

    gov_bills = sum(a.bills for a in allagents(model) if a isa Government)
    bank_bills = sum(a.bills for a in allagents(model) if a isa Bank)
    IMS.bills!(agent, gov_bills, bank_bills)
    
    tot_advances = sum(a.advances for a in allagents(model) if a isa Bank)
    IMS.advances!(agent, tot_advances)

    tot_l_fac = sum(a.lending_facility for a in allagents(model) if a isa Bank)
    tot_d_fac = sum(a.deposit_facility for a in allagents(model) if a isa Bank)
    IMS.facilities!(agent, tot_l_fac, tot_d_fac)
    IMS.networth!(agent)
    IMS.capital_balance!(agent)
    return model
end