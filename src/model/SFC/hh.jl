"""
Define households' actions.
"""

"""
    prev_vars!(agent::Household) → nothing

Update households' previous variables.
"""
function prev_vars!(agent::Household)
    agent.deposits_prev = agent.deposits
    agent.loans_prev = agent.loans
    agent.income_prev = agent.income
    agent.income_exp_prev = agent.income_exp 
    agent.networth_prev = agent.networth
    return nothing
end

"""
    consumption!(agent::Household, model) → agent.consumption, agent.nominal_consumption

Households make their consumption decisions. The outflow of consumption is then updated for the matching bank.
"""
function consumption!(agent::Household, model)
    agent.consumption = model.α1 * agent.income_exp / model[agent.belongToFirm].prices +  model.α2 * agent.networth_prev / model[agent.belongToFirm].prices
    agent.nominal_consumption = agent.consumption * model[agent.belongToFirm].prices
    
    if !ismissing(agent.belongToBank)
        model[agent.belongToBank].flow -= agent.nominal_consumption
    end

    if agent.consumption < 0
        println("negative C")
    elseif isnan(agent.consumption)
        println("NaN C")
    end
    return agent.consumption, agent.nominal_consumption
end

"""
    loans!(agent::Household, model) → agent.loans

Households receive loans from the corresponding bank based on their demand for loans.
"""
function loans!(agent::Household, model)
    agent.loans = model.γ * (agent.networth_prev + agent.nominal_consumption)
    model[agent.belongToBank].loans += agent.loans 
    return agent.loans
end

"""
    non_performing_loans!(agent::Household, model) → model

A proportion of households' loans is non-performing.
"""
function non_performing_loans!(agent::Household, model)
    model[agent.belongToBank].npl += model.l * agent.loans
    return model
end

"""
    taxes!(agent::Household, τ) → agent.taxes

Households pay taxes on wages.
"""
function taxes!(agent::Household, τ)
    agent.taxes = τ * agent.wages
    return agent.taxes
end

"""
    expected_income!(agent::Household, model) → agent.income_exp

Households compute their expected available income.
"""
function expected_income!(agent::Household, model)
    agent.income_exp = agent.income_exp_prev + model.ϕ * (agent.income_prev - agent.income_exp_prev)
    return agent.income_exp
end

"""
    income!(agent::Household, profits) → agent.income

Households compute their available income.
"""
function income!(agent::Household, profits)
    agent.income = agent.wages + agent.deposits_interests + profits - agent.taxes - agent.loans_interests
    if agent.income < 0
        println("negative Yd")
    elseif isnan(agent.income) 
        println("NaN Yd")
    end
    return agent.income
end

"""
    interests_payments!(agent::Household, model) → agent.loans_interests, agent.deposits_interests

Households compute their interest payments and receipts from loans and deposits of the previous period.
"""
function interests_payments!(agent::Household, model)
    agent.loans_interests = agent.loans_prev * model[agent.belongToBank].il_rate_prev
    model[agent.belongToBank].loans_interests += agent.loans_interests
    agent.deposits_interests = agent.deposits_prev * model[agent.belongToBank].id_rate_prev
    model[agent.belongToBank].deposits_interests += agent.deposits_interests
    return agent.loans_interests, agent.deposits_interests
end

"""
    deposits!(agent::Household) → agent.deposits

Households decide the amount of deposits they wish to hold (buffer variable).
"""
function deposits!(agent::Household, model) # id
    agent.deposits += (agent.loans - agent.loans_prev) + agent.income - agent.nominal_consumption
    model[agent.belongToBank].deposits += agent.deposits 
    if agent.deposits < 0
        println("negative Dh")
    elseif isnan(agent.income) 
        println("NaN Dh")
    end
    return agent.deposits
end

"""
    networth!(agent::Household) → agent.networth

Update households' networth.
"""
function networth!(agent::Household)
    agent.networth = agent.deposits - agent.loans
    return agent.networth
end

"""
    balance!(agent::Household) → agent.balance_current

Update households' balance for SFC checks.
"""
function balance!(agent::Household)
    agent.balance_current = (agent.loans - agent.loans_prev) + agent.income - agent.nominal_consumption - (agent.deposits - agent.deposits_prev)
    return agent.balance_current
end

"""
    SFC!(agent::Household, model) → model

Define households' SFC actions and update their accounting.
"""
function SFC!(agent::Household, model)
    IMS.deposits!(agent, model)
    IMS.networth!(agent)
    IMS.balance!(agent)
    return model
end