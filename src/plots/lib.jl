# Scenarios comparisons in the same plot
function ib_on_scenarios(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Overnight interbank loans", xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.ON_assets), 129600)
        lines!(trend; 
            label = "$(key.scenario) Uncertainty")
    end
    ax.xticks = 0:200:1200
  
    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function ib_term_scenarios(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Term interbank loans", xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.Term_assets), 129600)
        lines!(trend; 
            label = "$(key.scenario) Uncertainty")
    end
    ax.xticks = 0:200:1200
  

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function ib_term_rationing(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Term interbank rationing", xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((1 .- subdf.Term_liabs./subdf.term_demand), 129600)
        lines!(trend; 
            label = "$(key.scenario) Uncertainty")
    end
    ax.xticks = 0:200:1200
  

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function ib_on_rationing(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "ON interbank rationing", xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((1 .- subdf.ON_liabs./subdf.on_demand), 129600)
        lines!(trend; 
            label = "$(key.scenario) Uncertainty")
    end
    ax.xticks = 0:200:1200
  

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function margin_stability(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Margins of stability", xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.margin_stability), 129600)
        lines!(trend; 
            label = "$(key.scenario) Uncertainty")
    end
    ax.xticks =0:200:1200

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function am(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "ASF factor", xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.am), 129600)
        lines!(trend; 
            label = "$(key.scenario) Uncertainty")
    end
    ax.xticks =0:200:1200
  
    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function bm(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "RSF factor", xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.bm), 129600)
        lines!(trend; 
            label = "$(key.scenario) Uncertainty")
    end
    ax.xticks =0:200:1200
   

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function assets(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Total assets", xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.tot_assets), 129600)
        lines!(trend; 
            label = "$(key.scenario) Uncertainty")
    end
    ax.xticks =0:200:1200

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function liabilities(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Total liabilities", xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.tot_liabilities), 129600)
        lines!(trend; 
            label = "$(key.scenario) Uncertainty")
    end
    ax.xticks =0:200:1200
  
    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function pmb(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Borrowers' preferences for maturities", xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.pmb), 129600)
        lines!(trend; 
            label = "$(key.scenario) Uncertainty")
    end
    ax.xticks =0:200:1200

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function pml(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Lenders' preferences for maturities", xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.pml), 129600)
        lines!(trend; 
            label = "$(key.scenario) Uncertainty")
    end
    ax.xticks =0:200:1200
  
    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function deposit_facility(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Deposit facility", xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.deposit_facility), 1)
        lines!(trend; 
            label = "$(key.scenario) Uncertainty")
    end
    ax.xticks =0:200:1200

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function lending_facility(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Lending facility", xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.lending_facility), 129600)
        lines!(trend; 
            label = "$(key.scenario) Uncertainty")
    end
    ax.xticks =0:200:1200

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
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.loans), 129600)
        lines!(trend; 
            label = "$(key.scenario) Uncertainty")
    end
    ax.xticks =0:200:1200

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
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.il_rate), 129600)
        lines!(trend; 
            label = "$(key.scenario) Uncertainty")
    end
    ax.xticks =0:200:1200
   

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function output(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Firms' output", xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.output), 129600)
        lines!(trend; 
            label = "$(key.scenario) Uncertainty")
    end
    ax.xticks =0:200:1200

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)
    return fig
end

function prices(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Prices", xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.prices), 129600)
        lines!(trend; 
            label = "$(key.scenario) Uncertainty")
    end
    ax.xticks =0:200:1200
   

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function ib_rates_scenarios(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    axes = ((1,1), (1,2))
    gdf = @pipe df |>
        groupby(_, :scenario)

    for i in 1:length(gdf)
        ax = fig[axes[i]...] = Axis(fig, title = only(unique(gdf[i].scenario)))
        cycle_on, trend_on = hp_filter(gdf[i].ion, 129600)
        cycle_term, trend_term = hp_filter(gdf[i].iterm, 129600)
        lines!(trend_on; 
             label = "ON rate")
        lines!(trend_term; 
             label = "Term rate")
        lines!(gdf[i].icbt; linestyle = :dash, color = :lightgrey)     
        lines!(gdf[i].icbd;  linestyle = :dot, color = :black)
        lines!(gdf[i].icbl;  linestyle = :dot, color = :black)
        ax.xticks = 0:200:1200
    end

    ax1 = fig.content[1]
    ax2 = fig.content[2]

    ax1.ylabel = "Mean"
    ax1.xlabel = ax2.xlabel = "Steps"
    linkyaxes!(fig.content...)
    ax2.yticklabelsvisible = false
    ax2.yticksvisible = false


    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
    )

    return fig
end

function willingness(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    axes = ((1,1), (1,2))
    gdf = @pipe df |>
        groupby(_, :scenario)

    for i in 1:length(gdf)
        ax = fig[axes[i]...] = Axis(fig, title = only(unique(gdf[i].scenario)))
        cycle_on, trend_theta = hp_filter(gdf[i].θ, 1)
        cycle_term, trend_LbW = hp_filter(gdf[i].iterm, 129600)
        lines!(trend_theta; 
             label = "θ")
        lines!(trend_LbW; 
             label = "LbW")
        ax.xticks = 0:200:1200
    end

    ax1 = fig.content[1]
    ax2 = fig.content[2]

    ax1.ylabel = "Mean"
    ax1.xlabel = ax2.xlabel = "Steps"
    linkyaxes!(fig.content...)
    ax2.yticklabelsvisible = false
    ax2.yticksvisible = false

    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
    )

    return fig
end
