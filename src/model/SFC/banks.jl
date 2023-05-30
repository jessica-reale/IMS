"""
Define banks' actions.
"""

"""
    prev_vars!(agent::Bank) → nothing

Update banks' previous variables.
"""
function prev_vars!(agent::Bank)
    agent.deposits_prev = agent.deposits
    agent.hpm_prev = agent.hpm
    agent.loans_prev = agent.loans
    agent.il_rate_prev = agent.il_rate
    agent.id_rate_prev = agent.id_rate
    agent.advances_prev = agent.advances
    agent.bills_prev = agent.bills
    agent.bonds_prev = agent.bonds
    agent.npl_prev = agent.npl
    agent.lending_facility_prev = agent.lending_facility 
    agent.deposit_facility_prev = agent.deposit_facility
    agent.funding_costs_prev = agent.funding_costs
    # ib
    agent.ON_assets_prev = agent.ON_assets 
    agent.ON_liabs_prev = agent.ON_liabs
    agent.Term_assets_prev = agent.Term_assets 
    agent.Term_liabs_prev = agent.Term_liabs
    return nothing
end

"""
    reset_vars!(agent::Bank) → nothing

Reset banks' variables.
"""
function reset_vars!(agent::Bank, scenario)
    agent.ib_flag = false
    agent.flow = 0.0
    agent.loans = 0.0 
    agent.npl = 0.0
    agent.deposits = 0.0
    agent.loans_interests = 0.0
    agent.deposits_interests = 0.0
    agent.belongToBank = missing
    agent.on_demand = 0.0
    agent.term_demand = 0.0
    agent.on_supply = 0.0
    agent.term_supply = 0.0
    agent.tot_demand = 0.0
    agent.tot_supply = 0.0
    agent.tot_assets = 0.0
    agent.tot_liabilities = 0.0
    empty!(agent.ib_customers)
    if scenario == "Maturity"
        agent.am = 0.0
        agent.bm = 0.0
        agent.margin_stability = 0.0
        agent.actual_borr_ratio = 0.0
        agent.target_borr_ratio = 0.0
        agent.actual_lend_ratio = 0.0
        agent.target_lend_ratio = 0.0
        agent.pmb = 0.0
        agent.pml = 0.0
    end
    return nothing
end

"""
    reset_after_status!(agent::Bank) → nothing

Reset banks' variables after interbank status.
"""
function reset_after_status!(agent::Bank)
    agent.ON_assets = 0.0
    agent.Term_assets = 0.0
    agent.ON_liabs = 0.0
    agent.Term_liabs = 0.0
    return nothing
end

"""
    hpm!(agent::Bank, μ, v) → agent.hpm

Update banks' holdings of reserves.
"""
function hpm!(agent::Bank, μ, v)
    agent.hpm = (μ + v) * agent.deposits
    return agent.hpm
end

"""
    bills!(agent::Bank, model) → agent.bills

Update banks' holdings of bills (buffer variable). If bills are negative they are set to zero and banks ask for advances as buffer variable.
"""
function bills!(agent::Bank, model) #id
    agent.bills = max(0.0, min(agent.deposits + agent.npl + agent.lending_facility - agent.loans - model.μ * agent.deposits - agent.bonds - agent.deposit_facility, 
        sum(a.bills for a in allagents(model) if a isa Government) / (model.n_bj + model.n_bk)))
    return agent.bills
end

"""
    bonds!(agent::Bank) → agent.bonds

Update banks' bonds as dependent on non-performing-loans.
"""
function bonds!(agent::Bank)
    agent.bonds = agent.npl
    return agent.bonds
end

"""
    advances!(agent::Bank, model) → agent.advances

Update banks' advances. If bills are negative, advances act as buffer variable, otherwise banks ask for a proportion of current deposits.
"""
function advances!(agent::Bank, model) # alternative id
    if agent.bills == 0.0
        agent.advances = agent.loans + agent.deposit_facility + agent.hpm + agent.bonds - agent.deposits - agent.npl - agent.lending_facility
    else
        agent.advances =  model.v * agent.deposits
    end
    return agent.advances
end

"""
    update_status!(agent::Bank) → agent.status

Update banks' status in the interbank market: deficit, surplus or neutral.
"""
function update_status!(agent::Bank)
    if agent.flow < 0 && abs(agent.flow) > (agent.hpm - agent.hpm_prev)
        agent.status = :deficit
    elseif agent.flow > 0 && agent.flow > (agent.hpm - agent.hpm_prev)
        agent.status = :surplus
    else
        agent.status = :neutral
    end
    return agent.status
end

"""
    NSFR!(agent::Bank, model) → model

Update the elements of the Net Stable Funding Ratio (NSFR). The function is called 
when the scenario is "Maturity" and the margin of stability is weighted for the residual maturities of the NSFR.
"""
function NSFR!(agent::Bank, model)
    # end function prematurely if agent is neutral
    agent.status == :neutral && return

    agent.am = (model.m4 * agent.deposits_prev + model.m5 * agent.Term_liabs_prev) / agent.tot_liabilities
    agent.bm = 
        if agent.type == :business 
            (model.m1 * (agent.loans_prev + agent.ON_assets_prev) + model.m2 * (agent.bills_prev + agent.Term_assets_prev) + 
                model.m3 * agent.bonds_prev) / agent.tot_assets
        elseif agent.type == :commercial
            (model.m1 * agent.ON_assets_prev + model.m2 * (agent.loans_prev + agent.bills_prev + agent.Term_assets_prev) + 
                model.m3 * agent.bonds_prev) / agent.tot_assets
        end
    # update margin of stability
    agent.margin_stability = agent.am / agent.bm
    return model
end

""" 
    portfolio!(agent::Bank) → agent.tot_assets, agent.tot_liabilities

Update banks' asset holdings and liabilities.   
"""
function portfolio!(agent::Bank)
    agent.tot_assets = agent.loans_prev + agent.hpm_prev + agent.bills_prev + agent.bonds_prev + agent.ON_assets_prev + agent.Term_assets_prev + agent.deposit_facility_prev
    agent.tot_liabilities = agent.deposits_prev + agent.ON_liabs_prev + agent.Term_liabs_prev + agent.npl_prev + agent.lending_facility_prev + agent.advances_prev
    return agent.tot_assets, agent.tot_liabilities
end

"""
    lending_targets!(agent::Bank, scenario, rng) → agent.pml

Update lenders' preferences for overnight interbank assets: banks' are assumed to be indifferent to maturity considerations in 
the `Baseline` scenario. When the `Maturity` scenario is active, preferences depend on NSFR weights.
"""
function lending_targets!(agent::Bank, rng)
    # end function prematurely if agent is not surplus
    agent.status != :surplus && return

    agent.actual_lend_ratio = 1 - agent.bm
    agent.target_lend_ratio = 
        if agent.margin_stability >= 1.0
            agent.actual_lend_ratio
        else 
            rand(rng, Uniform(0.0, agent.actual_lend_ratio))
        end
    agent.pml = max(0.0, min(agent.actual_lend_ratio - agent.target_lend_ratio, 1.0))

    return agent.pml
end

"""
    borrowing_targets!(agent::Bank, rng) → agent.pmb

Update borrowers' preferences for overnight interbank assets: banks' are assumed to be indifferent to maturity considerations in 
the `Baseline` scenario. When the `Maturity` scenario is active, preferences depend on NSFR weights.
"""
function borrowing_targets!(agent::Bank, rng)
    # end function prematurely if agent is not deficit
    agent.status != :deficit && return 

    agent.actual_borr_ratio = 1 - agent.am
    agent.target_borr_ratio = 
        if agent.margin_stability < 1.0
            agent.actual_borr_ratio
        else 
            rand(rng, Uniform(0.0, agent.actual_borr_ratio))
        end
    agent.pmb = max(0.0, min(agent.actual_borr_ratio - agent.target_borr_ratio, 1.0))

    return agent.pmb
end

"""
    tot_demand!(agent::Bank) → agent.tot_demand

Deficit banks define their total demand for reserves as dependent on their current outflow and `ΔH`.
"""
function tot_demand!(agent::Bank)
    agent.status != :deficit && return
    
    agent.tot_demand = abs(agent.flow) - (agent.hpm - agent.hpm_prev)
    return agent.tot_demand
end

"""
    tot_supply!(agent::Bank) → agent.tot_supply

Surplus banks define their total demand for reserves as dependent on their current inflow and `ΔH`.
"""
function tot_supply!(agent::Bank)
    agent.status != :surplus && return
    
    agent.tot_supply = agent.flow - (agent.hpm - agent.hpm_prev)
    return agent.tot_supply
end

"""
    on_demand!(agent::Bank, model) → agent.on_demand

Banks define their demand for overnight interbank loans dependent on money market rates (`Baseline` scenario) 
and NSFR-based borrowing preferences (`Maturity` scenario). When the `Baseline` scenario is active, lenders accommodate borrowers' demand for funds 
in the overnight segment. Otherwise, see `on_supply!.
"""
function on_demand!(agent::Bank, model)
    if agent.status == :deficit && agent.ib_flag
        agent.on_demand = agent.tot_demand * (model.θ * agent.pmb)
        if model.scenario == "Baseline" 
            model[agent.belongToBank].on_supply += agent.on_demand
        end
    end
    return agent.on_demand
end

"""
    term_demand!(agent::Bank, model) → agent.term_demand

Banks define their demand for term interbank loans as a residual. When the `Baseline` scenario is active, lenders accommodate borrowers' demand for funds 
in the term segment. Otherwise, see `term_supply!`.
"""
function term_demand!(agent::Bank, model)
    if agent.status == :deficit && agent.ib_flag
        agent.term_demand = agent.tot_demand - agent.on_demand
        if model.scenario == "Baseline" 
            model[agent.belongToBank].term_supply += agent.term_demand
        end
    end
    return agent.term_demand
end

"""
    on_supply!(agent::Bank, LbW) → agent.on_supply

Banks define their supply for overnight interbank loans dependent on money market rates and NSFR-based lending preferences when the scenario
is "Maturity".
"""
function on_supply!(agent::Bank, LbW)
    if agent.status == :surplus && agent.ib_flag
        agent.on_supply = agent.tot_supply * (LbW * agent.pml)
    end
    return agent.on_supply
end

"""
    term_supply!(agent::Bank) → agent.term_supply

Banks define their supply for term interbank loans as a residual, when the scenario is "Maturity".
"""
function term_supply!(agent::Bank)
    if agent.status == :surplus && agent.ib_flag
        agent.term_supply = agent.tot_supply - agent.on_supply
    end
    return agent.term_supply
end

"""
    ib_on!(agent::Bank, model) → model

Updates overnight interbank assets and liabilities. When the `Baseline` scenario is active, lenders accommodate borrowers' demand for funds 
in the overnight segment. Otherwise, borrowers receive funds according to the short-side of the market.
"""
function ib_on!(agent::Bank, model)
    if agent.status == :deficit && agent.ib_flag
        if agent.on_demand > model[agent.belongToBank].on_supply
            agent.ON_liabs = model[agent.belongToBank].on_supply
            model[agent.belongToBank].ON_assets += agent.ON_liabs
        elseif agent.on_demand <= model[agent.belongToBank].on_supply
            agent.ON_liabs = agent.on_demand
            model[agent.belongToBank].ON_assets += agent.ON_liabs
        end
    end
    return model
end

"""
    ib_term!(agent::Bank, model) → model

Updates term interbank assets and liabilities. When the `Baseline` scenario is active, lenders accommodate borrowers' demand for funds 
in the term segment. Otherwise, borrowers receive funds according to the short-side of the market.
"""
function ib_term!(agent::Bank, model)
    if agent.status == :deficit && agent.ib_flag
        if agent.term_demand > model[agent.belongToBank].term_supply
            agent.Term_liabs = model[agent.belongToBank].term_supply
            model[agent.belongToBank].Term_assets += agent.Term_liabs
        elseif agent.term_demand <= model[agent.belongToBank].term_supply
            agent.Term_liabs = agent.term_demand
            model[agent.belongToBank].Term_assets += agent.Term_liabs
        end
    end
    return model
end

"""
    lending_facility!(agent::Bank) → agent.lending_facility

Deficit banks that do not find a suitable partner in the interbank market access the central bank's lending facility
to cover their outflows.    
"""
function lending_facility!(agent::Bank)
    if agent.status == :deficit && !agent.ib_flag
        agent.lending_facility = agent.tot_demand
    end
    return agent.lending_facility
end

"""
    deposit_facility!(agent::Bank) → agent.deposit_facility

Surplus banks that do not find a suitable partner in the interbank market access the central bank's deposit facility
to deposit their excess reserves deriving from payment inflows.    
"""
function deposit_facility!(agent::Bank)
    if agent.status == :surplus && !agent.ib_flag
        agent.deposit_facility = agent.tot_supply
    end
    return agent.deposit_facility
end

"""
    funding_costs!(agent::Bank, icbt, ion, iterm, icbl) → agent.funding_costs

Banks compute their funding costs according to their recourse to the interbank market and/or the central bank's lending facility.
"""
function funding_costs!(agent::Bank, icbt, ion, iterm, icbl)
    if agent.status == :deficit
        if agent.ib_flag
            if agent.ON_liabs > 0.0 && agent.Term_liabs > 0.0
                agent.funding_costs = (icbt + ion + iterm)/3
            elseif agent.ON_liabs > 0.0 && agent.Term_liabs == 0.0
                agent.funding_costs = (icbt + ion)/2
            elseif agent.ON_liabs == 0.0 && agent.Term_liabs > 0.0
                agent.funding_costs = (icbt + iterm)/2
            end
        else
            agent.funding_costs = (icbt + icbl)/2
        end
    else
        agent.funding_costs = icbt
    end
    return agent.funding_costs
end

"""
    credit_rates!(agent::Bank, χ1) → agent.il_rate, agent.id_rate

Banks determine lending and deposit rates on the credit market based on their previous period funding costs.
"""
function credit_rates!(agent::Bank, χ1)
    agent.il_rate = agent.funding_costs_prev + χ1
    agent.id_rate = agent.funding_costs_prev - χ1
    return agent.il_rate, agent.id_rate
end

"""
    interests_payments!(agent::Bank, model) → model

Banks make interest payments on bills, bonds, reserves, advances and central bank's facilities.
"""
function interests_payments!(agent::Bank, model)
    agent.bills_interests = model.ib * agent.bills_prev
    agent.bonds_interests = model.iblr * agent.bonds_prev
    agent.hpm_interests = model.icbt * agent.hpm_prev
    agent.advances_interests = model.icbt * agent.advances_prev
    agent.lending_facility_interests = model.icbl * agent.lending_facility_prev
    agent.deposit_facility_interests = model.icbd * agent.deposit_facility_prev
    return model
end

"""
    profits!(agent::Bank) → agent.profits

Banks compute their profits.
"""
function profits!(agent::Bank)
    agent.profits = agent.loans_interests + agent.hpm_interests + agent.bills_interests + agent.bonds_interests + agent.deposit_facility_interests - 
                agent.deposits_interests - agent.advances_interests - agent.lending_facility_interests
    return agent.profits
end

"""
    networth!(agent::Bank) → agent.networth

Banks update their networth.
"""
function networth!(agent::Bank)
    agent.networth = agent.loans + agent.deposit_facility + agent.hpm  + agent.bills + agent.bonds - agent.deposits - agent.advances - agent.lending_facility
    return agent.networth
end

"""
    current_balance!(agent::Bank) → agent.balance_current

Update banks' current balances for SFC checks.
"""
function current_balance!(agent::Bank)
    agent.balance_current =  agent.loans_interests + agent.hpm_interests + agent.bills_interests + agent.bonds_interests + agent.deposit_facility_interests - 
        agent.deposits_interests - agent.advances_interests - agent.lending_facility_interests - agent.profits
    return agent.balance_current
end

"""
    capital_balance!(agent::Bank) → agent.balance_capital

Update banks' capital balances for SFC checks.
"""
function capital_balance!(agent::Bank)
    agent.balance_capital = agent.advances + agent.deposits + agent.npl - agent.loans - agent.bills - agent.bonds - agent.hpm + 
        agent.lending_facility - agent.deposit_facility
    return agent.balance_capital
end

"""
    SFC!(agent::Bank, model) → model

Define banks' SFC actions and update their accounting.
"""
function SFC!(agent::Bank, model)
    IMS.hpm!(agent, model.μ, model.v)
    IMS.bills!(agent, model)
    IMS.advances!(agent, model)
    IMS.networth!(agent)
    IMS.capital_balance!(agent)
    return model
end