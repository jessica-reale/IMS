"""
    ids_by_type(T::DataType, model::ABM) → ids

Returns ids of agents per type defined as structs.
"""
function ids_by_type(T::DataType, model::ABM)
    ids = Int[]
    for id in Schedulers.randomly(model)
        if model[id] isa T
            push!(ids, id)
        end
    end
    return ids
end

"""
    SFC_checks!(model; explosive::Bool = false) → nothing

Checks for Stock-Flow Consistency. Allows for explosive dynamics through the Bool variable `explosive` which 
is set to `false` by default.
"""
function SFC_checks!(model; explosive::Bool = false)
    GDP = 
        if explosive
            sum(a.output for a in allagents(model) if a isa Firm) * sum(a.prices for a in allagents(model) if a isa Firm)
        else
            1.0
        end
    SFC_checks_net_worth!(model, GDP)
    SFC_checks_aggregate!(model, GDP)
    SFC_checks_balance!(model, GDP)
    SFC_explosive!(model, GDP)
    return nothing
end

"""
    SFC_checks_net_worth!(model, GDP; tol::Float64 = 1e-06) → nothing

Checks that the net worth of all sectors corresponds to the nominal value of tangible assets, i.e. capital.
"""
function SFC_checks_net_worth!(model, GDP; tol::Float64 = 1e-06)
    networth = sum(a.networth for a in allagents(model) if a isa Government) - 
            sum(a.networth for a in allagents(model) if !isa(a, Government))

    if abs(networth) - abs(sum(a.capital + a.Invent for a in allagents(model) if a isa Firm)) > tol * GDP
        @warn """
        Stock-flow error at $(model.step) for $(tol * GDP) tolerance level - Net Worth!
        Check whether the model explodes. To do so, modify in the `model_step` function the keyword of `SFC_checks!` as 
        `SFC_checks!(model; explosive = true)` and run the model checks again. If the problem persists, check the model or 
        initial values and sequence of events again.
        """
    end
    return nothing
end

"""
    SFC_checks_balance!(model, GDP; tol::Float64 = 1e-06) → nothing

Checks that net lending/borrowing positions of all sectors sum to zero.
"""
function SFC_checks_balance!(model, GDP; tol::Float64 = 1e-06)
    balance = sum(a.balance_current for a in allagents(model))

    if abs(balance) > tol * GDP
        println(abs(balance))
        @warn """ 
        Stock-flow error at $(model.step) for $(tol * GDP) tolerance level - Sectoral Balances!
        Check whether the model explodes. To do so, modify in the `model_step` function the keyword of `SFC_checks!` as 
        `SFC_checks!(model; explosive = true)` and run the model checks again. If the problem persists, check the model or 
        initial values and sequence of events again.
        """
    end
    return nothing
end
"""
    SFC_explosive!(model, GDP; tol::Float64 = 1e-05) → nothing

Checks that the SFC structure holds despite explosive dynamics.
"""
function SFC_explosive!(model, GDP; tol::Float64 = 1e-05)
    tot_balance = sum(a.balance_current for a in allagents(model)) + 
        sum(a.balance_capital for a in allagents(model) if a isa Firm || a isa CentralBank || a isa Bank)

    if abs(tot_balance)/GDP > tol
        println(abs(tot_balance))
        @warn """ 
        Stock-flow error at $(model.step) for $(tol * GDP) tolerance level - Explosive SFC issue!
        Check whether the model explodes. To do so, modify in the `model_step` function the keyword of `SFC_checks!` as 
        `SFC_checks!(model; explosive = true)` and run the model checks again. If the problem persists, check the model or 
        initial values and sequence of events again.
        """
    end
    return nothing
end

"""
    SFC_checks_aggregate!(model, GDP; tol::Float64 = 1e-06) → nothing

Checks the aggregation of variables between aggregate sectors and disaggregated ones.
"""
function SFC_checks_aggregate!(model, GDP; tol::Float64 = 1e-06)
    # check for aggregation errors
    Df = sum(a.deposits for a in allagents(model) if a isa Bank && a.type == :business) - 
         sum(a.deposits for a in allagents(model) if a isa Firm)
    Dh = sum(a.deposits for a in allagents(model) if a isa Bank && a.type == :commercial) - 
            sum(a.deposits for a in allagents(model) if a isa Household) 
    iDf = sum(a.deposits_interests for a in allagents(model) if a isa Firm) - 
        sum(a.deposits_interests for a in allagents(model) if a isa Bank && a.type == :business)
    iDh = sum(a.deposits_interests for a in allagents(model) if a isa Household) - 
        sum(a.deposits_interests for a in allagents(model) if a isa Bank && a.type == :commercial)
    Lf = sum(a.loans for a in allagents(model) if a isa Bank && a.type == :business) - sum(a.loans for a in allagents(model) if a isa Firm)
    iLf = sum(a.loans_interests for a in allagents(model) if a isa Firm) - 
        sum(a.loans_interests for a in allagents(model) if a isa Bank && a.type == :business)
    Lh = sum(a.loans for a in allagents(model) if a isa Bank && a.type == :commercial) - sum(a.loans for a in allagents(model) if a isa Household)
    iLh = sum(a.loans_interests for a in allagents(model) if a isa Household) - 
        sum(a.loans_interests for a in allagents(model) if a isa Bank && a.type == :commercial)
    B = sum(a.bills for a in allagents(model) if a isa Government) - sum(a.bills for a in allagents(model) if a isa CentralBank || a isa Bank)
    iB = model.ib * sum(a.bills_prev for a in allagents(model) if a isa CentralBank) + sum(a.bills_interests for a in allagents(model) if a isa Bank) - 
        model.ib * sum(a.bills_prev for a in allagents(model) if a isa Government)
    Blr = sum(a.bonds for a in allagents(model) if a isa Government) - sum(a.bonds for a in allagents(model) if a isa Bank)
    iBlr = model.iblr * sum(a.bonds_prev for a in allagents(model) if a isa Government) - 
        sum(a.bonds_interests for a in allagents(model) if a isa Bank)
    c = sum(a.consumption for a in allagents(model) if a isa Household) - sum(a.consumption for a in allagents(model) if a isa Firm)
    C = sum(a.nominal_consumption for a in allagents(model) if a isa Household) - sum(a.nominal_consumption for a in allagents(model) if a isa Firm)
    W = sum(a.wages for a in allagents(model) if a isa Household) - sum(a.wages for a in allagents(model) if a isa Firm)
    H = sum(a.hpm for a in allagents(model) if a isa CentralBank) - sum(a.hpm for a in allagents(model) if a isa Bank)
    iH = sum(a.hpm_interests for a in allagents(model) if a isa Bank) - model.icbt * sum(a.hpm_prev for a in allagents(model) if a isa CentralBank)
    A = sum(a.advances for a in allagents(model) if a isa CentralBank) - sum(a.advances for a in allagents(model) if a isa Bank)
    iA = sum(a.advances_interests for a in allagents(model) if a isa Bank) - model.icbt * sum(a.advances_prev for a in allagents(model) if a isa CentralBank)
    Rl = sum(a.lending_facility for a in allagents(model) if a isa CentralBank) - sum(a.lending_facility for a in allagents(model) if a isa Bank)
    iRl = model.icbl * sum(a.lending_facility_prev for a in allagents(model) if a isa CentralBank) - 
        sum(a.lending_facility_interests for a in allagents(model) if a isa Bank)
    Rd = sum(a.deposit_facility for a in allagents(model) if a isa CentralBank) - sum(a.deposit_facility for a in allagents(model) if a isa Bank)
    iRd = model.icbd * sum(a.deposit_facility_prev for a in allagents(model) if a isa CentralBank) - 
        sum(a.deposit_facility_interests for a in allagents(model) if a isa Bank)
    IB = if !isempty([id for id in allids(model) if model[id] isa Bank && model[id].status == :surplus]) && 
                !isempty([id for id in allids(model) if model[id] isa Bank && model[id].status == :deficit])
            sum(a.ON_assets + a.Term_assets for a in allagents(model) if a isa Bank && a.status == :surplus) - 
                sum(a.ON_liabs + a.Term_liabs for a in allagents(model) if a isa Bank && a.status == :deficit)
        else
            0.0
        end
    
    all_aggregate_vars = (Df, Dh, Lf, Lh, B, iB, C, W, IB, iLf, Rl, iRl, Rd, iRd, iLh, iDf, iDh, H, iH, A, iA, Blr, iBlr, c)

    any(>(tol * GDP), all_aggregate_vars) && @warn """ 
            Stock-flow error at $(model.step) for $(tol * GDP) tolerance level - Aggregation!
            Check whether the model explodes. To do so, modify in the `model_step` function the keyword of `SFC_checks!` as 
            `SFC_checks!(model; explosive = true)` and run the model checks again. If the problem persists, check the model or 
            initial values and sequence of events again.
            """

    return nothing
end