const colors = Makie.wong_colors()[5:end]


function credit_loans(df::DataFrame, param::Symbol; f::Bool = true)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, xlabel = "Steps", ylabel = "Moving Average")
    gdf = groupby(df, param)

    for i in 1:length(gdf)
        _, trend = hp_filter((gdf[i].loans[100:end]), 129600)
        lines!(movavg(trend, 200).x; color = colors[i],
            label = "$(param) = $(only(unique(gdf[i][!, param])))")
    end

    ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
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

function output(df::DataFrame, param::Symbol)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "GDP", xlabel = "Steps", ylabel = "Moving Average")
    gdf = groupby(df, param)

    for i in 1:length(gdf)
        _, trend = hp_filter((gdf[i].output[100:end]), 129600)
        lines!(movavg(trend, 200).x; color = colors[i],
            label = "$(param) = $(only(unique(gdf[i][!, param])))")
    end

    ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end
function big_ib_plots_sens(df, param)
    fig = Figure(resolution = (1250, 250), fontsize = 10)
    axes = ((1,1), (1,2), (1,3), (1,4))
    gdf = @pipe df |> 
        groupby(_, param)
    
    vars = (variables = [:Term_liabs, :ON_liabs, :lending_facility, :deposit_facility], 
        labels = ["Term segment", "Overnight segment", "Lending Facility", "Deposit facility"])     
            
    for i in 1:length(vars.variables)   
        ax = fig[axes[i]...] = Axis(fig, title = vars.labels[i])
        for j in 1:length(gdf)
            _, trend = hp_filter(gdf[j][!, vars.variables[i]][100:end], 129600)
            lines!(movavg(trend, 200).x; color = colors[j], label = "$(param) = $(only(unique(gdf[j][!, param])))")
        end
        ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
    end

    ax1 = fig.content[1]; ax2 = fig.content[2]; ax3 = fig.content[3];  ax4 = fig.content[4]; 
    ax1.ylabel = "Moving Average"
    ax1.xlabel = ax2.xlabel = ax3.xlabel = ax4.xlabel = "Steps"

    fig[end+1,1:4] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )
    return fig 
end

function stability_ib_plots_sens(df, param)
    fig = Figure(resolution = (1200, 700), fontsize = 10)
    axes = ((1,1:2), (2,1), (2,2), (3,1), (3,2))
    gdf = @pipe df |> 
        groupby(_, param)
    
    vars = (variables = [:margin_stability, :am, :bm, :pmb, :pml], 
        labels = ["Margin of stability", "ASF", "RSF",
            L"\Pi^{b}", L"\Pi^{l}"])   
            
    for i in 1:length(vars.variables)   
        ax = fig[axes[i]...] = Axis(fig, title = vars.labels[i])
        for j in 1:length(gdf)
            _, trend = hp_filter(gdf[j][!, vars.variables[i]][100:end], 129600)
            lines!(movavg(trend, 200).x; color = colors[j], label = "$(param) = $(only(unique(gdf[j][!, param])))")
        end
        ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
    end

    ax1 = fig.content[1]; 
    ax2 = fig.content[2]; ax3 = fig.content[3];
    ax4 = fig.content[4]; ax5 = fig.content[5];
    ax1.ylabel = ax2.ylabel = ax4.ylabel = "Moving Average"
    ax1.xlabel = ax4.xlabel = ax5.xlabel = "Steps"
    ax2.xticklabelsvisible = ax3.xticklabelsvisible = false
    ax2.xticksvisible = ax3.xticksvisible = false
    ax1.ytickformat = ax2.ytickformat = "{:.3f}"

    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )
    return fig
end