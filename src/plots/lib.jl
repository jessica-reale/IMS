# Scenarios comparisons in the same plot
function interest_ib_on(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Overnight interbank rate", xlabel = "Steps", ylabel = "Mean")
    gdf = @pipe df |>
        groupby(_, :shock)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.ion[100:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
        #lines!(subdf.icbt[100:end]; linestyle = :dash)
    end
    ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
    ax.xticklabelalign

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
        _, trend = hp_filter((subdf.iterm[100:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
        #lines!(subdf.icbt[100:end]; linestyle = :dash)
    end
    ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
  
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
        _, trend = hp_filter((subdf.loans[100:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
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

function scenarios_credit_rates(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Credit rates", xlabel = "Steps", ylabel = "Mean")
    gdf = @pipe df |> 
        groupby(_, :shock)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.il_rate[100:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
    end
    ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
   

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
        _, trend = hp_filter((subdf.output[100:end] .* subdf.prices[100:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
    end
    ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])

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
        _, trend = hp_filter((subdf.prices[100:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
    end
    ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
   
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
        _, trend = hp_filter((subdf.θ[100:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
    end
    ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
   
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
        _, trend = hp_filter((subdf.LbW[100:end]), 129600)
        lines!(trend; 
            label = "$(key.shock)-shock")
    end
    ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
   
    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

# Big plots 
function big_credit_firms_plots(df)
    fig = Figure(resolution = (1200, 300), fontsize = 10)
    axes = ((1,1), (1,2), (1,3))
    gdf = @pipe df |> 
        groupby(_, :shock)
    
    vars = (variables = [:loans, :output, :Invent], 
        labels = ["Loans", "Output", "Inventories"])   
            
    for i in 1:length(vars.variables)   
        ax = fig[axes[i]...] = Axis(fig, title = vars.labels[i])
        for j in 1:length(gdf)
            _, trend = hp_filter(gdf[j][!, vars.variables[i]][100:end], 129600)
            lines!(trend; label = only(unique(gdf[j].shock)))
        end
        ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
    end

    ax1 = fig.content[1]; ax2 = fig.content[2]; ax3 = fig.content[3];

    ax1.ylabel =  "Mean"
    ax1.xlabel = ax2.xlabel = ax3.xlabel = "Steps"

    fig[end+1,1:3] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )
   
    return fig 
end

function big_credit_hh_plots(df)
    fig = Figure(resolution = (1200, 300), fontsize = 10)
    axes = ((1,1), (1,2))
    gdf = @pipe df |> 
        groupby(_, :shock)
    
    vars = (variables = [:loans, :consumption], 
        labels = ["Loans", "Consumption"])   
            
    for i in 1:length(vars.variables)   
        ax = fig[axes[i]...] = Axis(fig, title = vars.labels[i])
        for j in 1:length(gdf)
            _, trend = hp_filter(gdf[j][!, vars.variables[i]][100:end], 129600)
            lines!(trend; label = only(unique(gdf[j].shock)))
        end
        ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
    end

    ax1 = fig.content[1]; ax2 = fig.content[2]

    ax1.ylabel =  "Mean"
    ax1.xlabel = ax2.xlabel = "Steps"

    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )
    return fig 
end

function big_ib_plots(df)
    fig = Figure(resolution = (1200, 700), fontsize = 10)
    axes = ((1,1), (1,2), (1,3), (2,1), (2,2), (2,3), (3,1), (3,2), (3,3))
    gdf = @pipe df |> 
        groupby(_, :shock)
    
    vars = (variables = [:ON_assets, :Term_assets, :deposit_facility, :lending_facility, :margin_stability, :am, :bm, :pmb, :pml], 
        labels = ["Overnight segment", "Term segment", "Deposit facility", "Lending Facility", "Margin of stability", "ASF", "RSF", 
            "Borrowers' preferences", "Lenders' preferences"])   
            
    for i in 1:length(vars.variables)   
        ax = fig[axes[i]...] = Axis(fig, title = vars.labels[i])
        for j in 1:length(gdf)
            _, trend = hp_filter(gdf[j][!, vars.variables[i]][100:end], 129600)
            lines!(trend; label = only(unique(gdf[j].shock)))
        end
        ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
    end

    ax1 = fig.content[1]; ax2 = fig.content[2]; ax3 = fig.content[3];
    ax4 = fig.content[4]; ax5 = fig.content[5]; ax6 = fig.content[6];
    ax7 = fig.content[7]; ax8 = fig.content[8]; ax9 = fig.content[9]

    ax1.ylabel = ax4.ylabel = ax7.ylabel = "Mean"
    ax7.xlabel = ax8.xlabel = ax9.xlabel = "Steps"
    ax1.xticklabelsvisible = ax2.xticklabelsvisible = ax3.xticklabelsvisible = 
        ax4.xticklabelsvisible = ax5.xticklabelsvisible = ax6.xticklabelsvisible = false
    
    ax1.xticksvisible = ax2.xticksvisible = ax3.xticksvisible =  
        ax4.xticksvisible = ax5.xticksvisible = ax6.xticksvisible = false
   
    fig[end+1,1:3] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )
    return fig 
end

function big_ib_baseline_plots(df)
    fig = Figure(resolution = (1250, 250), fontsize = 10)
    axes = ((1,1), (1,2), (1,3), (1,4))
    gdf = @pipe df |> 
        groupby(_, :shock)
    
    vars = (variables = [:ON_assets, :Term_assets, :deposit_facility, :lending_facility], 
        labels = ["Overnight segment", "Term segment", "Deposit facility", "Lending Facility"])   
            
    for i in 1:length(vars.variables)   
        ax = fig[axes[i]...] = Axis(fig, title = vars.labels[i])
        for j in 1:length(gdf)
            _, trend = hp_filter(gdf[j][!, vars.variables[i]][100:end], 129600)
            lines!(trend; label = only(unique(gdf[j].shock)))
        end
        ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
    end

    ax1 = fig.content[1]; ax2 = fig.content[2]; ax3 = fig.content[3];  ax4 = fig.content[4]; 
   

    ax1.ylabel = "Mean"
    ax1.xlabel = ax2.xlabel = ax3.xlabel = ax4.xlabel = "Steps"
   
    fig[end+1,1:4] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )
    return fig 
end

function big_rationing_plot(df)
    fig = Figure(resolution = (800, 300), fontsize = 10)
    axes = ((1,1), (1,2))
    gdf = @pipe df |> 
        groupby(_, :shock)
            
    vars = (variables_num = [:ON_liabs, :Term_liabs], variables_den = [:on_demand, :term_demand], labels = ["ON rationing", "Term rationing"])

    for i in 1:length(vars.variables_num)
        ax = fig[axes[i]...] = Axis(fig, title = vars.labels[i])
        for j in 1:length(gdf)
            _, trend = hp_filter((1 .- gdf[j][!, vars.variables_num[i]][100:end] ./ gdf[j][!, vars.variables_den[i]][100:end]), 129600)
            lines!(trend; label = only(unique(gdf[j].shock)))
        end
        ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
    end

    ax1 = fig.content[1]; ax2 = fig.content[2]
    
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

function big_ib_volumes(df)
    fig = Figure(resolution = (800, 400), fontsize = 10)
    axes = ((1,1), (1,2))
    gdf = @pipe df |> 
        groupby(_, :shock)
    
    vars = (variables = [:ON_assets, :Term_assets], 
        labels = ["Overnight segment", "Term segment"])   
            
    for i in 1:length(vars.variables)   
        ax = fig[axes[i]...] = Axis(fig, title = vars.labels[i])
        for j in 1:length(gdf)
            _, trend = hp_filter(gdf[j][!, vars.variables[i]][100:end], 129600)
            lines!(trend; label = only(unique(gdf[j].shock)))
        end
        ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
    end

    ax1 = fig.content[1]; ax2 = fig.content[2]

    ax1.ylabel = ax2.ylabel = "Mean"
    ax1.xlabel = ax2.xlabel  = "Steps"
   
    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )
    return fig 
end

function big_ib_by_status(df)
    fig = Figure(resolution = (1200, 300), fontsize = 10)
    axes = ((1,1), (1,2), (1,3))

    gdf = @pipe df |> 
        groupby(_, :shock)
    
    vars = (variables = [:margin_stability, :am, :bm], 
        labels = ["Margin of stability", "ASF", "RSF"])   
        
    for i in 1:length(vars.variables)   
        ax = fig[axes[i]...] = Axis(fig, title = vars.labels[i])
        for j in 1:length(gdf)
            _, trend = hp_filter(gdf[j][!, vars.variables[i]][100:end], 129600)
            lines!(trend; label = only(unique(gdf[j].shock)))
        end
        ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
    end

    ax1 = fig.content[1]; ax2 = fig.content[2]; ax3 = fig.content[3];

    ax1.ylabel =  "Mean"
    ax1.xlabel = ax2.xlabel = ax3.xlabel = "Steps"

    fig[end+1,1:3] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )
    return fig 
end

function big_ib_growth_plots(df)
    fig = Figure(resolution = (1200, 700), fontsize = 10)
    axes = ((1,1), (1,2), (1,3), (2,1), (2,2), (2,3), (3,1), (3,2), (3,3))
    colors = Makie.wong_colors()[2:end] # excludes blue used for "Missing" shock

    gdf = @pipe df |> filter(:shock => x -> x != "Missing", _) |>
        groupby(_, :shock)
    
    vars = (variables = [:ON_assets_growth, :Term_assets_growth, :deposit_facility_growth, :lending_facility_growth, :margin_stability_growth, :am_growth, :bm_growth, :pmb_growth, :pml_growth], 
    labels = ["Overnight segment", "Term segment", "Deposit facility", "Lending Facility ", "Margin of stability ", 
    "ASF", "RSF ", "Borrowers' preferences ", "Lenders' preferences"]) 
    
    for i in 1:length(vars.variables)   
        ax = fig[axes[i]...] = Axis(fig, title = vars.labels[i])
        for j in 1:length(gdf)
            _, trend = hp_filter(gdf[j][!, vars.variables[i]][100:end], 129600)
            lines!(trend; label = only(unique(gdf[j].shock)), 
                color = colors[j])
        end
        ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
    end

    ax1 = fig.content[1]; ax2 = fig.content[2]; ax3 = fig.content[3];
    ax4 = fig.content[4]; ax5 = fig.content[5]; ax6 = fig.content[6];
    ax7 = fig.content[7]; ax8 = fig.content[8]; ax9 = fig.content[9]

    ax1.ylabel = ax4.ylabel = ax7.ylabel = "Growth rates"
    ax7.xlabel = ax8.xlabel = ax9.xlabel = "Steps"
    ax1.xticklabelsvisible = ax2.xticklabelsvisible = ax3.xticklabelsvisible = 
        ax4.xticklabelsvisible = ax5.xticklabelsvisible = ax6.xticklabelsvisible = false
    
    ax1.xticksvisible = ax2.xticksvisible = ax3.xticksvisible =  
        ax4.xticksvisible = ax5.xticksvisible = ax6.xticksvisible = false
   
    fig[end+1,1:3] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )
    return fig 
end

function big_ib_growth_baseline_plots(df)
    fig = Figure(resolution = (1250, 250), fontsize = 10)
    axes = ((1,1), (1,2), (1,3), (1,4))
    colors = Makie.wong_colors()[2:end] # excludes blue used for "Missing" shock

    gdf = @pipe df |> filter(:shock => x -> x != "Missing", _) |>
        groupby(_, :shock)
    
    vars = (variables = [:ON_assets_growth, :Term_assets_growth, :deposit_facility_growth, :lending_facility_growth], 
    labels = ["Overnight segment", "Term segment", "Deposit facility", "Lending Facility ", "Margin of stability "]) 

    for i in 1:length(vars.variables)   
        ax = fig[axes[i]...] = Axis(fig, title = vars.labels[i])
        for j in 1:length(gdf)
            _, trend = hp_filter(gdf[j][!, vars.variables[i]][100:end], 129600)
            lines!(trend; label = only(unique(gdf[j].shock)), 
                color = colors[j])
        end
        ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
    end

    ax1 = fig.content[1]; ax2 = fig.content[2]; ax3 = fig.content[3];  ax4 = fig.content[4];
   
    ax1.ylabel = "Growth rates"
    ax1.xlabel = ax2.xlabel = ax3.xlabel = ax4.xlabel = "Steps"
    
    fig[end+1,1:4] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )
    return fig 
end