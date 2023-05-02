
# Scenarios comparisons in the same plot
function ib_on_scenarios(df)
    fig = Figure(resolution = (800, 400))
    ax = fig[1,1] = Axis(fig, title = "Overnight interbank loans", xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.IBon), 1600)
        lines!(trend; 
            label = "$(key.scenario)")
    end
    ax.xticks = 0:200:1200

    fig[1, end+1] = Legend(fig, ax; 
        orientation = :vertical, tellwidth = true)

    return fig
end

function ib_term_scenarios(df)
    fig = Figure(resolution = (800, 400))
    ax = fig[1,1] = Axis(fig, title = "Term interbank loans", xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.IBterm), 1600)
        lines!(trend; 
            label = "$(key.scenario)")
    end
    ax.xticks = 0:200:1200

    fig[1, end+1] = Legend(fig, ax; 
        orientation = :vertical, tellwidth = true)

    return fig
end

function margin_stability(df)
    fig = Figure(resolution = (800, 400))
    ax = fig[1,1] = Axis(fig, title = "Margins of stability", xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.margin_stability), 1600)
        lines!(trend; 
            label = "$(key.scenario)")
    end
    ax.xticks = 0:200:1200

    fig[1, end+1] = Legend(fig, ax; 
        orientation = :vertical, tellwidth = true)

    return fig
end

function am(df)
    fig = Figure(resolution = (800, 400))
    ax = fig[1,1] = Axis(fig, title = "ASF factor", xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.am[50:end]), 1600)
        lines!(trend; 
            label = "$(key.scenario)")
    end
    ax.xticks = 0:200:1200

    fig[1, end+1] = Legend(fig, ax; 
        orientation = :vertical, tellwidth = true)

    return fig
end

function bm(df)
    fig = Figure(resolution = (800, 400))
    ax = fig[1,1] = Axis(fig, title = "RSF factor", xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.bm[50:end]), 1600)
        lines!(trend; 
            label = "$(key.scenario)")
    end
    ax.xticks = 0:200:1200

    fig[1, end+1] = Legend(fig, ax; 
        orientation = :vertical, tellwidth = true)

    return fig
end

function pmb(df)
    fig = Figure(resolution = (800, 400))
    ax = fig[1,1] = Axis(fig, title = "Borrowers' preferences for maturities", xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.pmb), 1600)
        lines!(trend; 
            label = "$(key.scenario)")
    end
    ax.xticks = 0:200:1200

    fig[1, end+1] = Legend(fig, ax; 
        orientation = :vertical, tellwidth = true)

    return fig
end

function pml(df)
    fig = Figure(resolution = (800, 400))
    ax = fig[1,1] = Axis(fig, title = "Lenders' preferences for maturities", xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.pml), 1600)
        lines!(trend; 
            label = "$(key.scenario)")
    end
    ax.xticks = 0:200:1200

    fig[1, end+1] = Legend(fig, ax; 
        orientation = :vertical, tellwidth = true)

    return fig
end

function scenarios_loans(df; f::Bool = true)
    fig = Figure(resolution = (800, 400))
    ax = fig[1,1] = Axis(fig, xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.loans), 1600)
        lines!(trend; 
            label = "$(key.scenario)")
    end
    ax.xticks = 0:200:1200

    ax.title = if f 
        "Firms Loans"
        else
            "Households Loans"
        end

    fig[1, end+1] = Legend(fig, ax; 
        orientation = :vertical, tellwidth = true)

    return fig
end

function output(df)
    fig = Figure(resolution = (800, 400))
    ax = fig[1,1] = Axis(fig, title = "Firms' output", xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.output), 1600)
        lines!(trend; 
            label = "$(key.scenario)")
    end
    ax.xticks = 0:200:1200

    fig[1, end+1] = Legend(fig, ax; 
        orientation = :vertical, tellwidth = true)

    return fig
end

function prices(df)
    fig = Figure(resolution = (800, 400))
    ax = fig[1,1] = Axis(fig, title = "Prices", xlabel = "Steps", ylabel = "Mean")
    gdf = groupby(df, :scenario)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.prices), 1600)
        lines!(trend; 
            label = "$(key.scenario)")
    end
    ax.xticks = 0:200:1200

    fig[1, end+1] = Legend(fig, ax; 
        orientation = :vertical, tellwidth = true)

    return fig
end

function ib_rates_scenarios(df)
    fig = Figure(resolution = (1200, 800))
    axes = ((1,1), (2,1), (1,2), (2,2))
    gdf = @pipe df |>
        filter(r -> r.scenario in ["Baseline", "Corridor", "Uncertainty", "Width"], _) |>
        groupby(_, :scenario)

    for i in 1:length(gdf)
        ax = fig[axes[i]...] = Axis(fig, title = only(unique(gdf[i].scenario)))
        cycle_on, trend_on = hp_filter(gdf[i].ion, 1600)
        cycle_term, trend_term = hp_filter(gdf[i].iterm, 1600)
        lines!(trend_on; 
             label = "ON rate")
        lines!(trend_term; 
             label = "Term rate")
        lines!(gdf[i].icbt; linestyle = :dot, color = :black)     
        lines!(gdf[i].icbd;  linestyle = :dot, color = :black)
        lines!(gdf[i].icbl;  linestyle = :dot, color = :black)
        ax.xticks = 0:200:1200
    end

    ax1 = fig.content[1]; ax3 = fig.content[3]
    ax2 = fig.content[2]; ax4 = fig.content[4]

    ax1.ylabel = ax2.ylabel = "Mean"
    ax2.xlabel = ax4.xlabel = "Steps"
    linkyaxes!(fig.content...)
    ax3.yticklabelsvisible = ax4.yticklabelsvisible = false
    ax3.yticksvisible = ax4.yticksvisible = false
    ax1.xticklabelsvisible = ax3.xticklabelsvisible = false
    ax1.xticksvisible = ax3.xticksvisible = false

    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
    )

    return fig
end

function willingness(df)
    fig = Figure(resolution = (1200, 800))
    axes = ((1,1), (2,1), (1,2), (2,2))
    gdf = @pipe df |>
        filter(r -> r.scenario in ["Baseline", "Corridor", "Uncertainty", "Width"], _) |>
        groupby(_, :scenario)

    for i in 1:length(gdf)
        ax = fig[axes[i]...] = Axis(fig, title = only(unique(gdf[i].scenario)))
        cycle_on, trend_theta = hp_filter(gdf[i].θ, 1600)
        cycle_term, trend_LbW = hp_filter(gdf[i].iterm, 1600)
        lines!(trend_theta; 
             label = "θ")
        lines!(trend_LbW; 
             label = "LbW")
        ax.xticks = 0:200:1200
    end

    ax1 = fig.content[1]; ax3 = fig.content[3]
    ax2 = fig.content[2]; ax4 = fig.content[4]

    ax1.ylabel = ax2.ylabel = "Mean"
    ax2.xlabel = ax4.xlabel = "Steps"
    linkyaxes!(fig.content...)
    ax3.yticklabelsvisible = ax4.yticklabelsvisible = false
    ax3.yticksvisible = ax4.yticksvisible = false
    ax1.xticklabelsvisible = ax3.xticklabelsvisible = false
    ax1.xticksvisible = ax3.xticksvisible = false

    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
    )

    return fig
end
