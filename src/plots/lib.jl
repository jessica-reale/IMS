const BANKS_TYPE = ("business", "commercial")
const BANKS_TYPE_LABELS = (L"\text{Business}", L"\text{Commercial}")
const IB_STATUS = ("deficit", "surplus")
const IB_LABELS = (L"\text{Deficit}", L"\text{Surplus}")
const SCENARIOS_LABELS = (L"\text{Missing}", L"\text{Corridor}", L"\text{Width}", L"\text{Uncertainty}")

function plots_variables_growth(fig, axes, gdf, vars)
    for i in 1:length(vars.variables)   
        ax = fig[axes[i]...] = Axis(fig, title = vars.labels[i])
        for j in 2:length(gdf)
            _, trend = hp_filter((((gdf[j][!, vars.variables[i]][100:end] .- gdf[1][!, vars.variables[i]][100:end])) ./ gdf[1][!, vars.variables[i]][100:end]) .* 100, 129600)
            lines!(trend; color = Makie.wong_colors()[j] ,  label = only(unique(gdf[j].shock)))
        end
        ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
    end
end

function plots_variables_levels(fig, axes, gdf, vars)
    for i in 1:length(vars.variables)   
        ax = fig[axes[i]...] = Axis(fig, title = vars.labels[i])
        for j in 1:length(gdf)
            _, trend = hp_filter(gdf[j][!, vars.variables[i]][100:end], 129600)
            lines!(trend; label = only(unique(gdf[j].shock)))
        end
        ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
    end
end

# Big plots 
function big_credit_firms_plots(df)
    fig = Figure(resolution = (800, 400), fontsize = 16)
    axes = ((1,1), (1,2))
    gdf = @pipe df |> 
        groupby(_, :shock)

    vars = (variables = [:loans, :output], 
        labels = [L"\text{Loans}", L"\text{Output}"])   
            
    plots_variables_growth(fig, axes, gdf, vars)

    ax1 = fig.content[1]; ax2 = fig.content[2]
    ax1.ylabel =  L"\text{Growth rates (%)}"
    ax1.xlabel = ax2.xlabel = L"\text{Steps}"

    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )
   
    return fig 
end

function big_credit_hh_plots(df)
    fig = Figure(resolution = (800, 400), fontsize = 16)
    axes = ((1,1), (1,2))
    gdf = @pipe df |> 
        groupby(_, :shock)

    vars = (variables = [:loans, :consumption], 
        labels = [L"\text{Loans}", L"\text{Consumption}"])   
            
    plots_variables_growth(fig, axes, gdf, vars)

    ax1 = fig.content[1]; ax2 = fig.content[2]
    ax1.ylabel =  L"\text{Mean}"
    ax1.xlabel = ax2.xlabel = L"\text{Steps}"

    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )
    return fig 
end

function stability_ib_plots(df)
    fig = Figure(resolution = (1200, 600), fontsize = 16)
    axes = ((1:2,1), (1,2), (1,3), (2,2), (2,3))
    gdf = @pipe df |> 
        groupby(_, :shock)
    
    vars = (variables = [:margin_stability, :am, :bm, :pmb, :pml], 
        labels = [L"\text{Margin of stability}", L"\text{ASF} a_{m}", L"\text{RSF} b_{m}", 
            L"\Pi^{b}", L"\Pi^{l}"])   
            
    plots_variables_growth(fig, axes, gdf, vars)

    ax1 = fig.content[1]; 
    ax2 = fig.content[2]; ax3 = fig.content[3];
    ax4 = fig.content[4]; ax5 = fig.content[5];
    ax1.ylabel = ax2.ylabel = ax4.ylabel = L"\text{Growth rates (%)}"
    ax1.xlabel = ax4.xlabel = ax5.xlabel = L"\text{Steps}"
    ax2.xticklabelsvisible = ax3.xticklabelsvisible = false 
    ax2.xticksvisible = ax3.xticksvisible = false
    ax4.ytickformat = "{:.1f}"

    fig[end+1,1:3] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )
    return fig 
end

function stability_ib_plots_levels(df)
    fig = Figure(resolution = (1200, 600), fontsize = 16)
    axes = ((1:2,1), (1,2), (1,3), (2,2), (2,3))
    gdf = @pipe df |> 
        groupby(_, :shock)
    
    vars = (variables = [:margin_stability, :am, :bm, :pmb, :pml], 
        labels = [L"\text{Margin of stability}", L"\text{ASF} a_{m}", L"\text{RSF} b_{m}",
        L"\Pi^{b}", L"\Pi^{l}"])   
            
    plots_variables_levels(fig, axes, gdf, vars)

    ax1 = fig.content[1]; 
    ax2 = fig.content[2]; ax3 = fig.content[3];
    ax4 = fig.content[4]; ax5 = fig.content[5];
    ax1.ylabel = ax2.ylabel = ax4.ylabel = L"\text{Mean}"
    ax1.xlabel = ax4.xlabel = ax5.xlabel = L"\text{Steps}"
    ax2.xticklabelsvisible = ax3.xticklabelsvisible = false
    ax2.xticksvisible = ax3.xticksvisible = false
    ax1.ytickformat = ax2.ytickformat = "{:.3f}"

    fig[end+1,1:3] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )
    return fig 
end

function big_ib_plots(df)
    fig = Figure(resolution = (1200, 400), fontsize = 16)
    axes = ((1,1), (1,2), (1,3), (1,4))
    gdf = @pipe df |> 
        groupby(_, :shock)   

    vars = (variables = [:Term_liabs, :ON_liabs, :lending_facility, :deposit_facility], 
        labels = [L"\text{Term segment}", L"\text{Overnight segment}", L"\text{Lending facility}", L"\text{Deposit facility}"])   
            
    plots_variables_growth(fig, axes, gdf, vars)

    ax1 = fig.content[1]; ax2 = fig.content[2]; ax3 = fig.content[3];  ax4 = fig.content[4]; 
    ax1.ylabel = L"\text{Growth rate (%)}"
    ax1.xlabel = ax2.xlabel = ax3.xlabel = ax4.xlabel = L"\text{Steps}"
   
    fig[end+1,1:4] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )
    return fig 
end

function big_ib_plots_levels(df)
    fig = Figure(resolution = (1200, 400), fontsize = 16)
    axes = ((1,1), (1,2), (1,3), (1,4))
    gdf = @pipe df |> 
        groupby(_, :shock)
    
    vars = (variables = [:Term_liabs, :ON_liabs, :lending_facility, :deposit_facility], 
        labels = [L"\text{Term segment}", L"\text{Overnight segment}", L"\text{Lending facility}", L"\text{Deposit facility}"])     
            
    plots_variables_levels(fig, axes, gdf, vars)

    ax1 = fig.content[1]; ax2 = fig.content[2]; ax3 = fig.content[3];  ax4 = fig.content[4]; 
    ax1.ylabel = L"\text{Mean}"
    ax1.xlabel = ax2.xlabel = ax3.xlabel = ax4.xlabel = L"\text{Steps}"

    fig[end+1,1:4] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )
    return fig 
end

function big_rationing_plot(df)
    fig = Figure(resolution = (800, 400), fontsize = 16)
    axes = ((1,1), (1,2))
    gdf = @pipe df |> 
        groupby(_, :shock)
           
    vars = (variables_num = [:ON_liabs, :Term_liabs], variables_den = [:on_demand, :term_demand], labels = [L"\text{ON rationing}", L"\text{Term rationing}"])

    for i in 1:length(vars.variables_num)
        ax = fig[axes[i]...] = Axis(fig, title = vars.labels[i])
        for j in 1:length(gdf)
            _, trend = hp_filter((gdf[j][!, vars.variables_den[i]][100:end] .- gdf[j][!, vars.variables_num[i]][100:end]), 129600)
            lines!(trend; label = only(unique(gdf[j].shock)))
        end
        ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
    end

    ax1 = fig.content[1]; ax2 = fig.content[2]
    ax1.ylabel = L"\text{Mean}"
    ax1.xlabel = ax2.xlabel = L"\text{Steps}"
    #linkyaxes!(fig.content...)
    #ax2.yticklabelsvisible = false
    #ax2.yticksvisible = false

    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )
    return fig 
end

function big_ib_by_status(df)
    fig = Figure(resolution = (1200, 300), fontsize = 16)
    axes = ((1,1), (1,2), (1,3))
    gdf = @pipe df |> 
        groupby(_, :shock)

    vars = (variables = [:margin_stability, :am, :bm], 
        labels = [L"\text{Margin of stability}", L"\text{ASF} a_{m}", L"\text{RSF} b_{m}"])   
        
    plots_variables_growth(fig, axes, gdf, vars)

    ax1 = fig.content[1]; ax2 = fig.content[2]; ax3 = fig.content[3];
    ax1.ylabel =  L"\text{Mean}"
    ax1.xlabel = ax2.xlabel = ax3.xlabel = L"\text{Steps}"

    fig[end+1,1:3] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )
    return fig 
end

function interest_ib(df)
    fig = Figure(resolution = (1200, 400), fontsize = 16)
    axes = ((1, 1), (1,2), (1,3), (1,4))
    gdf = @pipe df |>
        groupby(_, :shock)

    for i in 1:length(gdf)
        ax = fig[axes[i]...] = Axis(fig, title = SCENARIOS_LABELS[i])
        cycle_on, trend_on = hp_filter(gdf[i].ion[100:end], 1600)
        cycle_term, trend_term = hp_filter(gdf[i].iterm[100:end], 1600)
        lines!(trend_on; 
             label = L"\text{ON rate}")
        lines!(trend_term; 
             label = L"\text{Term rate}")
        lines!(gdf[i].icbt[100:end]; linestyle = :dot, color = :black)     
        lines!(gdf[i].icbd[100:end];  linestyle = :dot, color = :black)
        lines!(gdf[i].icbl[100:end];  linestyle = :dot, color = :black)
        ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])   
    end

    ax1 = fig.content[1]; ax2 = fig.content[2]; ax3 = fig.content[3];  ax4 = fig.content[4]; 
    ax1.ylabel = L"\text{Mean}"
    ax1.xlabel = ax2.xlabel = ax3.xlabel = ax4.xlabel = L"\text{Steps}"

    fig[end+1,1:4] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
    )

    return fig
end

function theta_lbw(df)
    fig = Figure(resolution = (1200, 400), fontsize = 16)
    axes = ((1, 1), (1,2), (1,3), (1,4))
    gdf = @pipe df |>
        groupby(_, :shock)

    for i in 1:length(gdf)
        ax = fig[axes[i]...] = Axis(fig, title = SCENARIOS_LABELS[i])
        cycle_on, trend_theta = hp_filter(gdf[i].θ[100:end], 1600)
        cycle_term, trend_LbW = hp_filter(gdf[i].LbW[100:end], 1600)
        lines!(trend_theta; 
             label = "θ")
        lines!(trend_LbW; 
             label =  L"L_{b}W")
        ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])   
    end

    ax1 = fig.content[1]; ax2 = fig.content[2]; ax3 = fig.content[3];  ax4 = fig.content[4]; 
    ax1.ylabel = L"\text{Mean}"
    ax1.xlabel = ax2.xlabel = ax3.xlabel = ax4.xlabel = L"\text{Steps}"
    
    fig[end+1,1:4] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
    )

    return fig
end

function ib_demand_levels(df)
    fig = Figure(resolution = (800, 400), fontsize = 16)
    axes = ((1,1), (1,2))
    gdf = @pipe df |> 
        groupby(_, [:shock])

    vars = (variables = [:on_demand, :term_demand], 
        labels = [L"\text{Overnigth demand}", L"\text{Term demand}"])   
            
    plots_variables_levels(fig, axes, gdf, vars)

    ax1 = fig.content[1]; ax2 = fig.content[2]
    ax1.ylabel = L"\text{Mean}"
    ax1.xlabel = ax2.xlabel  = L"\text{Steps}"

    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )

    return fig
end

function by_status(fig::Figure, axes, gdf::GroupedDataFrame, var::Symbol)
    for i in eachindex(IB_STATUS)
        ax = fig[axes[i]...] = Axis(fig, title =  IB_LABELS[i])
        for j in 1:length(gdf)
            sdf = filter(r -> r.status == IB_STATUS[i], gdf[j])
            _, trend = hp_filter(sdf[!, var][100:end], 129600)
            lines!(trend; label = only(unique(gdf[j].shock)))
        end
        ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])   
    end
end

function flows_by_status_levels(df)
    fig = Figure(resolution = (800, 400), fontsize = 16)
    axes = ((1,1), (1,2))
    gdf = @pipe df |> 
        groupby(_, [:shock])

    by_status(fig, axes, gdf, :flow)

    ax1 = fig.content[1]; ax2 = fig.content[2]
    ax1.ylabel = L"\text{Mean}"
    ax1.xlabel = ax2.xlabel  = L"\text{Steps}"

    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )

    return fig
end

function stability_by_status_levels(df)
    fig = Figure(resolution = (800, 400), fontsize = 16)
    axes = ((1,1), (1,2))
    gdf = @pipe df |> 
        groupby(_, [:shock])

    by_status(fig, axes, gdf, :margin_stability)

    ax1 = fig.content[1]; ax2 = fig.content[2]
    ax1.ylabel = L"\text{Mean}"
    ax1.xlabel = ax2.xlabel  = L"\text{Steps}"

    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )

    return fig
end

function ASF_by_status_levels(df)
    fig = Figure(resolution = (800, 400), fontsize = 16)
    axes = ((1,1), (1,2))
    gdf = @pipe df |> 
        groupby(_, [:shock])

    by_status(fig, axes, gdf, :am)

    ax1 = fig.content[1]; ax2 = fig.content[2]
    ax1.ylabel = L"\text{Mean}"
    ax1.xlabel = ax2.xlabel  = L"\text{Steps}"

    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )

    return fig
end

function RSF_by_status_levels(df)
    fig = Figure(resolution = (800, 400), fontsize = 16)
    axes = ((1,1), (1,2))
    gdf = @pipe df |> 
        groupby(_, [:shock])

    by_status(fig, axes, gdf, :bm)

    ax1 = fig.content[1]; ax2 = fig.content[2]
    ax1.ylabel = L"\text{Mean}"
    ax1.xlabel = ax2.xlabel  = L"\text{Steps}"

    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )

    return fig
end

function loans_by_status_levels(df)
    fig = Figure(resolution = (800, 400), fontsize = 16)
    axes = ((1,1), (1,2))
    gdf = @pipe df |> 
        groupby(_, [:shock])

    by_status(fig, axes, gdf, :loans)

    ax1 = fig.content[1]; ax2 = fig.content[2]
    ax1.ylabel = L"\text{Mean}"
    ax1.xlabel = ax2.xlabel  = L"\text{Steps}"

    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )

    return fig
end

function by_type(fig::Figure, axes, gdf::GroupedDataFrame, var::Symbol)
    for i in eachindex(BANKS_TYPE)
        ax = fig[axes[i]...] = Axis(fig, title =  BANKS_TYPE_LABELS[i])
        for j in 1:length(gdf)
            sdf = filter(r -> r.type == BANKS_TYPE[i], gdf[j])
            _, trend = hp_filter(sdf[!, var][100:end], 129600)
            lines!(trend; label = only(unique(gdf[j].shock)))
        end
        ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])   
    end
end

function flows_by_type_levels(df)
    fig = Figure(resolution = (800, 400), fontsize = 16)
    axes = ((1,1), (1,2))
    gdf = @pipe df |> 
        groupby(_, [:shock])

    by_type(fig, axes, gdf, :flow)

    ax1 = fig.content[1]; ax2 = fig.content[2]
    ax1.ylabel = L"\text{Mean}"
    ax1.xlabel = ax2.xlabel  = L"\text{Steps}"

    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )

    return fig
end

function stability_by_type_levels(df)
    fig = Figure(resolution = (800, 400), fontsize = 16)
    axes = ((1,1), (1,2))
    gdf = @pipe df |> 
        groupby(_, [:shock])

    by_type(fig, axes, gdf, :margin_stability)

    ax1 = fig.content[1]; ax2 = fig.content[2]
    ax1.ylabel = L"\text{Mean}"
    ax1.xlabel = ax2.xlabel  = L"\text{Steps}"

    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )

    return fig
end

function ASF_by_type_levels(df)
    fig = Figure(resolution = (800, 400), fontsize = 16)
    axes = ((1,1), (1,2))
    gdf = @pipe df |> 
        groupby(_, [:shock])

    by_type(fig, axes, gdf, :am)

    ax1 = fig.content[1]; ax2 = fig.content[2]
    ax1.ylabel = L"\text{Mean}"
    ax1.xlabel = ax2.xlabel  = L"\text{Steps}"

    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )

    return fig
end

function RSF_by_type_levels(df)
    fig = Figure(resolution = (800, 400), fontsize = 16)
    axes = ((1,1), (1,2))
    gdf = @pipe df |> 
        groupby(_, [:shock])

    by_type(fig, axes, gdf, :bm)

    ax1 = fig.content[1]; ax2 = fig.content[2]
    ax1.ylabel = L"\text{Mean}"
    ax1.xlabel = ax2.xlabel  = L"\text{Steps}"

    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )

    return fig
end

function credit_rates_by_type_levels(df)
    fig = Figure(resolution = (800, 400), fontsize = 16)
    axes = ((1,1), (1,2))
    gdf = @pipe df |> 
        groupby(_, [:shock])

    by_type(fig, axes, gdf, :il_rate)

    ax1 = fig.content[1]; ax2 = fig.content[2]
    ax1.ylabel = L"\text{Mean}"
    ax1.xlabel = ax2.xlabel  = L"\text{Steps}"

    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )

    return fig
end

function loans_by_type_levels(df)
    fig = Figure(resolution = (800, 400), fontsize = 16)
    axes = ((1,1), (1,2))
    gdf = @pipe df |> 
        groupby(_, [:shock])

    by_type(fig, axes, gdf, :loans)

    ax1 = fig.content[1]; ax2 = fig.content[2]
    ax1.ylabel = L"\text{Mean}"
    ax1.xlabel = ax2.xlabel  = L"\text{Steps}"

    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )

    return fig
end