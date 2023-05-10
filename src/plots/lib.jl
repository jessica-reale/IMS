# Scenarios comparisons in the same plot
function ib_on(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Overnight interbank loans", xlabel = "Steps", ylabel = "Mean")
    gdf = @pipe df |> 
        groupby(_, :shock)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.ON_assets[50:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
    end
    ax.xticks = 100:200:1200
  
    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function interest_ib_on(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Overnight interbank rate", xlabel = "Steps", ylabel = "Mean")
    gdf = @pipe df |>
        groupby(_, :shock)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.ion[50:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
        #lines!(subdf.icbt[50:end]; linestyle = :dash)
    end
    ax.xticks = 100:200:1200
  
    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function interest_ib_term(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Term interbank rate", xlabel = "Steps", ylabel = "Mean")
    gdf = @pipe df |>
        groupby(_, :shock)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.iterm[50:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
        #lines!(subdf.icbt[50:end]; linestyle = :dash)
    end
    ax.xticks = 100:200:1200
  
    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function ib_term(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Term interbank loans", xlabel = "Steps", ylabel = "Mean")
    gdf = @pipe df |> 
        groupby(_, :shock)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.Term_assets[50:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
    end
    ax.xticks = 100:200:1200
  

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function ib_term_rationing(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Term interbank rationing", xlabel = "Steps", ylabel = "Mean")
    gdf = @pipe df |> 
        groupby(_, :shock)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((1 .- subdf.Term_liabs[50:end]./subdf.term_demand[50:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
    end
    ax.xticks = 100:200:1200
  

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function ib_on_rationing(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "ON interbank rationing", xlabel = "Steps", ylabel = "Mean")
    gdf = @pipe df |> 
        groupby(_, :shock)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((1 .- subdf.ON_liabs[50:end]./subdf.on_demand[50:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
    end
    ax.xticks = 100:200:1200
  

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function margin_stability(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Margins of stability", xlabel = "Steps", ylabel = "Mean")
    gdf = @pipe df |> 
        groupby(_, :shock)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.margin_stability[50:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
    end
    ax.xticks = 100:200:1200

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function am(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "ASF factor", xlabel = "Steps", ylabel = "Mean")
    gdf = @pipe df |> 
        groupby(_, :shock)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.am[50:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
    end
    ax.xticks = 100:200:1200
  
    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function bm(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "RSF factor", xlabel = "Steps", ylabel = "Mean")
    gdf = @pipe df |> 
        groupby(_, :shock)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.bm[50:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
    end
    ax.xticks = 100:200:1200
   

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function assets(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Total assets", xlabel = "Steps", ylabel = "Mean")
    gdf = @pipe df |> 
        groupby(_, :shock)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.tot_assets[50:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
    end
    ax.xticks = 100:200:1200

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function liabilities(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Total liabilities", xlabel = "Steps", ylabel = "Mean")
    gdf = @pipe df |> 
        groupby(_, :shock)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.tot_liabilities[50:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
    end
    ax.xticks = 100:200:1200
  
    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function pmb(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Borrowers' preferences for maturities", xlabel = "Steps", ylabel = "Mean")
    gdf = @pipe df |> 
        groupby(_, :shock)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.pmb[50:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
    end
    ax.xticks = 100:200:1200

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function pml(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Lenders' preferences for maturities", xlabel = "Steps", ylabel = "Mean")
    gdf = @pipe df |> 
        groupby(_, :shock)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.pml[50:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
    end
    ax.xticks = 100:200:1200
  
    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function deposit_facility(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Deposit facility", xlabel = "Steps", ylabel = "Mean")
    gdf = @pipe df |> 
        groupby(_, :shock)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.deposit_facility[50:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
    end
    ax.xticks = 100:200:1200

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function lending_facility(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Lending facility", xlabel = "Steps", ylabel = "Mean")
    gdf = @pipe df |> 
        groupby(_, :shock)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.lending_facility[50:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
    end
    ax.xticks = 100:200:1200

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

# Credit market
function scenarios_loans(df; f::Bool = true)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, xlabel = "Steps", ylabel = "Mean")
    gdf = @pipe df |> 
        groupby(_, :shock)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.loans[50:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
    end
    ax.xticks = 100:200:1200

    ax.title = if f 
        "Firms Loans"
        else
            "Households Loans"
        end

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function scenarios_credit_rates(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Credit rates", xlabel = "Steps", ylabel = "Mean")
    gdf = @pipe df |> 
        groupby(_, :shock)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.il_rate[50:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
    end
    ax.xticks = 100:200:1200
   

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function output(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "GDP", xlabel = "Steps", ylabel = "Mean")
    gdf = @pipe df |> 
        groupby(_, :shock)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.output[50:end] .* subdf.prices[50:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
    end
    ax.xticks = 100:200:1200

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)
    return fig
end

function prices(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Prices", xlabel = "Steps", ylabel = "Mean")
    gdf = @pipe df |> 
        groupby(_, :shock)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.prices[50:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
    end
    ax.xticks = 100:200:1200
   
    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function theta(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Borrowers' money market parameter", xlabel = "Steps", ylabel = "Mean")
    gdf = @pipe df |> 
        groupby(_, :shock)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.θ[50:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
    end
    ax.xticks = 100:200:1200
   
    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function LbW(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Lenders' money market parameter", xlabel = "Steps", ylabel = "Mean")
    gdf = @pipe df |> 
        groupby(_, :shock)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.LbW[50:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
    end
    ax.xticks = 100:200:1200
   
    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end