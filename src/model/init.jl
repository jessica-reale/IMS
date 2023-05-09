"""
Initialise model and agent types, compute initial values and distribute them among the model's sectors
and set initial market interactions.
"""

"""
    init_model(; seed::UInt32 = UInt32(96100), scenario::String = "Baseline", shock::String = "Missing", properties...) → model

Initialise the model.    
"""
function init_model(; seed::UInt32 = UInt32(96100), scenario::String = "Baseline", shock::String = "Missing",
        properties...) 
        if shock in ["Missing", "Corridor", "Width"] && scenario in ["Baseline", "Maturity"]
            model = ABM(Union{Government, CentralBank, Firm, Household, Bank};
                properties = Parameters(; shock, scenario, properties...), 
                scheduler = Schedulers.Randomly(),
                rng = Xoshiro(seed),
                warn = false # turns off Agents.jl warning of Union types
            )

            init_agents!(model)
            set_model_init_params(model)
            distribute_SS_values(model)
            real_sector_interactions!(model)
            credit_sector_interactions!(model)
        else
            error("You provided a shock named $(shock) or a scenario named $(scenario) that is not yet implemented. Check for typos or add the scenario/shock.")
        end
    return model
end

"""
    init_agents!(model::ABM) → model

Initialise and add agent types to the model.    
"""
function init_agents!(model::ABM)
    # initialise Households
    for id = 1:model.n_hh
        a = Household(
            id = id,
        )
        add_agent!(a, model)
    end

    # initialise Firms
    for id = (model.n_hh + 1):(model.n_hh + model.n_f)
        a = Firm(
            id = id,
        )
        add_agent!(a, model)
    end

    # initialise commercial Banks 
    for id = (model.n_hh + model.n_f + 1):(model.n_hh + model.n_f + model.n_bj)
        a = Bank(
            id = id,
            type = :commercial,
        )
        add_agent!(a, model)
    end

    # initialise business Banks 
    for id = (model.n_hh + model.n_f + model.n_bj + 1):(model.n_hh + model.n_f + model.n_bj + model.n_bk)
        a = Bank(
            id = id,
            type = :business, 
        )     
        add_agent!(a, model)
    end

    # initialise Government
    a = Government(
        id = model.n_hh + model.n_f + model.n_bj + model.n_bk + 1
    )
    add_agent!(a, model)

    # initialise CentralBank
    a = CentralBank(
        id = model.n_hh + model.n_f + model.n_bj + model.n_bk + 2
    )
    add_agent!(a, model)

    return model
end

"""
    SS_initial(model) → all_variables

Compute the SS values of the model. The function returns `all_variables` which is an
NTuple that links variable names to their corrisponding initial values. More, it updates the SS-given value
of `model.α2`, trhows a warning if variables are negative and performs the initial Stock-Flow consistency checks.
"""
function SS_initial(model)
    # exogenous variables and parameters
    icbt = model.ib # => Pcb = 0.0
    il = 0.0335
    id = 0.0155
    K = 3038.0
    # eqs
    Pcb = 0.0
    y = ((model.g  * model.ω) / model.pr - Pcb) / (((model.τ * model.ω) / model.pr) - model.ib * model.r)
    N = y / model.pr
    W = model.ω * N
    T = model.τ * W
    UC = W / y
    p = UC * (1 + model.ρ)
    G = model.g * p
    B = y * model.r
    i = model.gk * K
    I = i * p
    c = y - i - model.g 
    C = c * p
    invent_target = y
    invent = invent_target
    Invent = invent * UC
    Df = model.γ * W
    Lf = K + Invent + Df # from I = ΔK or b.s. matrix
    Pf = C + G + I + id * Df - W - il * Lf
    Yd = C
    α2_SS = (C - model.α1 * Yd) / (B + Lf - Df)
    NWh = (C - model.α1 * Yd) / α2_SS
    Lh = model.γ * (C + NWh)
    Dh = NWh + Lh
    Hj = (model.μ + model.v) * Dh
    Hk = (model.μ + model.v) * Df
    H = Hj + Hk
    Bj = max(0.0, min(Dh - Lh - model.μ * Dh, B))
    Bk = max(0.0, min(Df - Lf - model.μ * Df, B))
    Aj = 
        if Bj == 0.0
            Hj + Lh - Dh
        else
            model.v * Dh
        end
    Ak = 
        if Bk == 0.0
            Hk + Lf - Df
        else
            model.v * Df
        end
    A = Aj + Ak
    Bcb = B - Bj - Bk
    Pbj = il * Lh - id * Dh + model.ib * Bj + icbt * Hj - icbt * Aj
    Pbk = il * Lf - id * Df + model.ib * Bk + icbt * Hk - icbt * Ak
    # sectoral net worths: balance sheet matrix
    GD = B
    NWcb = Bcb - H + A
    NWbj = Lh + Hj - Dh - Aj + Bj
    NWbk = Lf + Hk - Df - Ak + Bk
    NWf = K + Invent + Df - Lf

    # collect all variables
    all_variables = (N, UC, p, K, y, Invent, invent, 
                    invent_target, W, T, B, I, i, Lf, 
                    C, c, G, Yd, Df, NWh, Lh, Dh, Hj, Hk, 
                    H, Bj, Bk, Ak, Aj, A, Bcb, 
                    Pbj, Pbk, Pf, il, id)

    # checks for negative initial values
    any(<(0.0), all_variables) && @warn "Some initial values are negative, check the parameters and/or the equations again!"

    # checks for networth balance and hidden equation at SS
    SS_SFC_checks(GD, NWh, NWcb, NWbj, NWbk, NWf, K, Invent)
    
    # update SS-given parameters
    model.α2 = α2_SS

    return all_variables
end

"""
    SS_SFC_checks(GD, NWh, NWcb, NWbj, NWbk, NWf, K; tol::Float64 = 1e-06) → nothing

Perform SFC checks for initial values calculation at the Steady State.
"""
function SS_SFC_checks(GD, NWh, NWcb, NWbj, NWbk, NWf, K, Invent; tol::Float64 = 1e-06)
    if abs((GD - (NWh + NWcb + NWbj + NWbk + NWf))) - abs((K + Invent)) > tol
        @warn "Initial values calculation does not respect stock-flow consistency - Net Worth!
            Check equations and parameters and try again."
    end
    if abs(NWcb) > tol
        @warn "Initial values calculation does not respect stock-flow consistency - Hidden Equation!
            Check equations and parameters and try again."
    end
    return nothing
end

"""
    distribute_SS_values(model) → model

Distribute SS values to aggregate sectors (Government and Central Bank) and to heterogenous sectors homogeneously.
"""
function distribute_SS_values(model)
    # take variables names and corresponding initial values
    (N, UC, p, K, y, Invent, invent, 
    invent_target, W, T, B, I, i, Lf, 
    C, c, G, Yd, Df, NWh, Lh, Dh, Hj, Hk, 
    H, Bj, Bk, Ak, Aj, A, Bcb, 
    Pbj, Pbk, Pf, il, id) = SS_initial(model)

    for a in allagents(model)
        if isa(a, Government)
            a.spending = G
            a.taxes = T
            a.bills = B
        elseif isa(a, CentralBank)
            a.bills = Bcb
            a.hpm = H
            a.advances = A
        elseif isa(a, Household)
            a.consumption = c / model.n_hh
            a.nominal_consumption = C / model.n_hh
            a.income = Yd / model.n_hh
            a.income_exp = a.income
            a.wages = W / model.n_hh
            a.taxes = T / model.n_hh
            a.loans = Lh / model.n_hh
            a.deposits = Dh / model.n_hh
            a.networth = NWh / model.n_hh
        elseif isa(a, Firm)
            a.consumption = c / model.n_f
            a.nominal_consumption = C / model.n_f
            a.investments = i / model.n_f
            a.nominal_investments = I / model.n_f
            a.capital = K / model.n_f
            a.output = y / model.n_f
            a.workers = N / model.n_f
            a.invent = invent / model.n_f
            a.invent_exp = a.invent
            a.invent_target = invent_target / model.n_f
            a.sales = a.output
            a.sales_exp = a.sales
            a.Invent = Invent / model.n_f
            a.wages = W / model.n_f
            a.deposits = Df / model.n_f
            a.loans = Lf / model.n_f
            a.profits = Pf / model.n_f
            a.prices = p
            a.unit_costs = UC
        elseif isa(a, Bank) && a.type == :commercial
            a.deposits = Dh / model.n_bj
            a.advances = Aj / model.n_bj
            a.bills = Bj / model.n_bj
            a.hpm = Hj / model.n_bj
            a.loans = Lh / model.n_bj
            a.funding_costs = model.icbt
            a.il_rate = il
            a.id_rate = id
            a.profits = Pbj / model.n_bj
            # NSFR
            a.tot_assets = a.loans + a.hpm + a.bills
            a.tot_liabilities = a.deposits + a.advances
            a.am = (model.m4 * a.deposits) / a.tot_liabilities
            a.bm = (model.m1 * a.loans + model.m2 * a.bills) / a.tot_assets
            a.margin_stability = a.am/ a.bm
        elseif isa(a, Bank) && a.type == :business
            a.deposits = Df / model.n_bk
            a.advances = Ak / model.n_bk
            a.bills = Bk / model.n_bk
            a.hpm = Hk / model.n_bk
            a.loans = Lf / model.n_bk
            a.funding_costs = model.icbt
            a.il_rate = il
            a.id_rate = id
            a.profits = Pbk / model.n_bk
            # NSFR
            a.tot_assets = a.loans + a.hpm + a.bills
            a.tot_liabilities = a.deposits + a.advances
            a.am = (model.m4 * a.deposits) / a.tot_liabilities
            a.bm = (model.m1 * a.loans + model.m2 * a.bills) / a.tot_assets
            a.margin_stability = a.am/ a.bm
        end
    end
    return model
end

function set_model_init_params(model)
    model.a0 = rand(model.rng, Uniform(0.0, 1.0))
    model.a1 = rand(model.rng, Uniform(0.0, 1.0))
    model.a2 = rand(model.rng, Uniform(0.0, 1.0))
    model.a3 = rand(model.rng, Uniform(0.0, 1.0))
    model.a4 = rand(model.rng, Uniform(0.0, 1.0))
    return model
end

"""
    real_sector_interactions!(model) → model

Match households and firms for consumption and wages exchanges in the real sector.    
"""
function real_sector_interactions!(model)
    HPF = round(Int, model.n_hh/model.n_f)

    for i in 1:model.n_f
        for id in (HPF*(i-1)+1):(HPF*i)
            model[id].belongToFirm = model.n_hh + i
            push!(model[model.n_hh + i].customers, id)
        end
    end
    return model
end

"""
    credit_sector_interactions!(model) → model

Match households and firms to banks in the credit market.    
"""
function credit_sector_interactions!(model)
    APBk = round(Int, model.n_f/model.n_bk)
    for i in 1:model.n_bk
        for id in (APBk*(i-1) + model.n_hh + 1):(APBk*i + model.n_hh)
            model[id].belongToBank = model.n_hh + model.n_f + model.n_bj +  i
            push!(model[model.n_hh + model.n_f +  model.n_bj + i].firms_customers, id)
        end
    end

    APBj = round(Int, model.n_hh/model.n_bj)
    for i in 1:model.n_bj
        for id in (APBj*(i-1)+1):(APBj*i)
            model[id].belongToBank = model.n_hh + model.n_f + i
            push!(model[model.n_hh + model.n_f + i].hh_customers, id)
        end
    end
    return model
end
