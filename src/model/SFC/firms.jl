"""
Define firms' actions.
"""

"""
    prev_vars!(agent::Firm) → nothing

Update firms' previous variables.
"""
function prev_vars!(agent::Firm)
    agent.capital_prev = agent.capital
    agent.deposits_prev = agent.deposits
    agent.loans_prev = agent.loans
    agent.wages_prev = agent.wages
    agent.invent_prev = agent.invent 
    agent.invent_exp_prev = agent.invent_exp
    agent.Invent_prev = agent.Invent 
    agent.sales_prev = agent.sales 
    agent.sales_exp_prev = agent.sales_exp
    agent.unit_costs_prev = agent.unit_costs
    return nothing
end

"""
    prices!(agent::Firm, ρ) → agent.prices

Firms make their pricing decisions.
"""
function prices!(agent::Firm, ρ)
    agent.prices = agent.unit_costs_prev * (1 + ρ)
    return agent.prices
end

"""
    unit_costs!(agent::Firm) → agent.unit_costs

Firms update their unit_costs.
"""
function unit_costs!(agent::Firm)
    agent.unit_costs = agent.wages / agent.output
    return agent.unit_costs
end

"""
    investments!(agent::Firm) → agent.investments, agent.nominal_investments

Firms make their investments decisions.
"""
function investments!(agent::Firm, gk)
    agent.investments = gk * agent.capital_prev
    agent.nominal_investments = agent.prices * agent.investments
    return agent.investments, agent.nominal_investments
end

"""
    capital!(agent::Firm, δ) → agent.capital

Firms make capital investments.
"""
function capital!(agent::Firm, δ)
    agent.capital = (1 - δ) * agent.capital_prev + agent.nominal_investments
    return agent.capital
end

"""
    consumption!(agent::Firm, model) → agent.consumption

Firms update their customers' consumption. The inflow of consumption is then updated for the matching bank.
"""
function consumption!(agent::Firm, model)
    agent.consumption = sum(model[a].consumption for a in agent.customers)
    agent.nominal_consumption = agent.consumption * agent.prices 

    if !ismissing(agent.belongToBank)
        model[agent.belongToBank].flow += agent.nominal_consumption
    end

    if agent.consumption < 0
        println("negative cons")
    elseif isnan(agent.consumption)
        println("NaN cons")
    end
    return agent.consumption, agent.nominal_consumption
end

"""
    output!(agent::Firm, β, ϕ, σ) → agent.output

Firms update their expectations on sales and inventories and produce output.
"""
function output!(agent::Firm, β, ϕ, σ)
    agent.sales_exp = β * agent.sales_prev + (1 - β) * agent.sales_exp_prev
    agent.invent_target =  σ * agent.sales_exp
    agent.invent_exp = agent.invent_exp_prev + ϕ * (agent.invent_target - agent.invent_exp_prev)
    agent.output = agent.sales_exp + agent.invent_exp - agent.invent_prev

    if agent.output < 0
        println("negative Y")
    elseif isnan(agent.output)
        println("NaN Y")
    end
    return agent.output
end

"""
    sales!(agent::Firm) → agent.sales

Firms compute their real sales.
"""
function sales!(agent::Firm, g)
    agent.sales = agent.consumption + agent.investments + g
    return agent.sales 
end

"""
    inventories!(agent::Firm) → agent.invent, agent.Invent

Firms compute update their inventory holdings.
"""
function inventories!(agent::Firm)
    agent.invent += agent.output - agent.sales
    agent.Invent = agent.invent * agent.unit_costs

    if agent.sales < 0
        println("negative s")
    elseif isnan(agent.sales)
        println("NaN s")
    end
    return agent.invent, agent.Invent
end

"""
    rationing!(agent::Firm, model) → model

Ration consumers if firms' sales exceed output and previous real inventories. The function also updates the corresponding flows for
the matched banks.
"""
function rationing!(agent::Firm, model)
    if agent.sales > agent.output + agent.invent_prev
        diff = agent.sales - agent.output - agent.invent_prev
        agent.sales -= diff
        agent.consumption -= diff
        agent.nominal_consumption -= diff * agent.prices
        model[agent.belongToBank].flow -= diff * agent.prices
        for id in agent.customers 
            model[id].consumption -= diff / length(agent.customers)
            model[id].nominal_consumption -= (diff * agent.prices) / length(agent.customers)
            model[model[id].belongToBank].flow -= (diff * agent.prices) / length(agent.customers)
        end
    end
    return model
end

"""
    wages!(agent::Firm, model) → agent.wages

Firms pay wages. Wages are paid to households and the corresponding inflow is updated for hhs' banks. Firms' outflow of wages is 
updated to firms' matching banks.
"""
function wages!(agent::Firm, model)
    agent.workers = agent.output / model.pr
    agent.wages = model.ω * agent.workers

    for id in agent.customers
        model[id].wages = agent.wages / length(agent.customers)
        model[model[id].belongToBank].flow += model[id].wages
    end
    if !ismissing(agent.belongToBank)
        model[agent.belongToBank].flow -= agent.wages
    end

    if agent.wages < 0
        println("negative W")
    elseif isnan(agent.wages)
        println("NaN W")
    end
    return agent.wages
end

"""
    deposits!(agent::Firm, model) → agent.deposits

Firms update their deposit holdings at the bank as a proportion of previous period wages.
"""
function deposits!(agent::Firm, model)
    agent.deposits = model.gd * agent.wages_prev
    model[agent.belongToBank].deposits += agent.deposits
    if agent.deposits < 0
        println("negative Df")
    elseif isnan(agent.deposits)
        println("NaN Df")
    end
    return agent.deposits
end

"""
    profits!(agent::Firm, spending) → agent.profits

Firms compute their profits which are then distributed to households.
"""
function profits!(agent::Firm, spending) # id
    agent.profits = agent.nominal_consumption + agent.nominal_investments + spending + (agent.Invent - agent.Invent_prev) - 
        agent.wages + agent.deposits_interests - agent.loans_interests
    if agent.profits < 0 
        println("negative Pf")
    elseif isnan(agent.profits)
        println("NaN Pf")
    end
    return agent.profits
end

"""
    interests_payments!(agent::Firm, model) → agent.loans_interests, agent.deposits_interests   

Firms update their interests payments and receipts from previous period loans and deposits.
"""
function interests_payments!(agent::Firm, model)
    agent.loans_interests = agent.loans_prev * model[agent.belongToBank].il_rate_prev
    model[agent.belongToBank].loans_interests += agent.loans_interests
    agent.deposits_interests = agent.deposits_prev * model[agent.belongToBank].id_rate_prev
    model[agent.belongToBank].deposits_interests += agent.deposits_interests
    return agent.loans_interests, agent.deposits_interests
end

"""
    loans!(agent::Firm, model) → agent.loans

Firms receive loans from the corresponding bank as buffer variable.
"""
function loans!(agent::Firm, model) # id
    agent.loans += agent.nominal_investments + (agent.Invent - agent.Invent_prev) + (agent.deposits - agent.deposits_prev)
    model[agent.belongToBank].loans += agent.loans
    return agent.loans
end

"""
    non_performing_loans!(agent::Firm, model) → model

A proportion of firms' loans is non-performing.
"""
function non_performing_loans!(agent::Firm, model)
    model[agent.belongToBank].npl += model.l * agent.loans
    return model
end

"""
    networth!(agent::Firm) → agent.networth

Firms update their networth.
"""
function networth!(agent::Firm)
    agent.networth = agent.capital + agent.Invent + agent.deposits - agent.loans
    return agent.networth
end

"""
    current_balance!(agent::Firm, spending) → agent.balance_current

Update firms' current balances for SFC checks.
"""
function current_balance!(agent::Firm, spending)
    agent.balance_current = agent.nominal_consumption + agent.nominal_investments + spending + (agent.Invent - agent.Invent_prev) - 
        agent.wages + agent.deposits_interests - agent.loans_interests - agent.profits
    return agent.balance_current
end

"""
    capital_balance!(agent::Firm) → agent.balance_capital

Update firms' capital balances for SFC checks.
"""
function capital_balance!(agent::Firm)
    agent.balance_capital = (agent.loans - agent.loans_prev) - (agent.deposits - agent.deposits_prev) - agent.nominal_investments - 
        (agent.Invent - agent.Invent_prev)
    return agent.balance_capital
end
"""
    SFC!(agent::Firm, model) → model

Define firms' SFC actions and update their accounting.
"""
function SFC!(agent::Firm, model)
    IMS.networth!(agent)
    IMS.capital_balance!(agent)
    return model
end