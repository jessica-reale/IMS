# Big plots 
function big_credit_firms_plots(df)
    fig = Figure(resolution = (800, 400), fontsize = 10)
    axes = ((1,1), (1,2))
    gdf = @pipe df |> 
        groupby(_, :shock)
    
    vars = (variables = [:loans, :output], 
        labels = ["Loans", "Output"])   
            
    for i in 1:length(vars.variables)   
        ax = fig[axes[i]...] = Axis(fig, title = vars.labels[i])
        for j in 2:length(gdf)
            _, trend = hp_filter((gdf[j][!, vars.variables[i]][100:end]) ./ gdf[1][!, vars.variables[i]][100:end], 129600)
            lines!(trend; label = only(unique(gdf[j].shock)))
        end
        ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
    end

    ax1 = fig.content[1]; ax2 = fig.content[2]

    ax1.ylabel =  "Growth rates (%)"
    ax1.xlabel = ax2.xlabel = "Steps"

    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )
   
    return fig 
end

function big_credit_hh_plots(df)
    fig = Figure(resolution = (800, 400), fontsize = 10)
    axes = ((1,1), (1,2))
    gdf = @pipe df |> 
        groupby(_, :shock)
    
    vars = (variables = [:loans, :consumption], 
        labels = ["Loans", "Consumption"])   
            
    for i in 1:length(vars.variables)   
        ax = fig[axes[i]...] = Axis(fig, title = vars.labels[i])
        for j in 2:length(gdf)
            _, trend = hp_filter((gdf[j][!, vars.variables[i]][100:end]) ./ gdf[1][!, vars.variables[i]][100:end], 129600)
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
    
    vars = (variables = [:ON_liabs, :Term_liabs, :deposit_facility, :lending_facility, :margin_stability, :am, :bm, :pmb, :pml], 
        labels = ["Overnight segment", "Term segment", "Deposit facility", "Lending Facility", "Margin of stability", "ASF", "RSF", 
            L"\Pi^{b}", L"\Pi^{l}"])   
            
    for i in 1:length(vars.variables)   
        ax = fig[axes[i]...] = Axis(fig, title = vars.labels[i])
        for j in 2:length(gdf)
            _, trend = hp_filter(((gdf[j][!, vars.variables[i]][100:end] .- gdf[1][!, vars.variables[i]][100:end])./gdf[1][!, vars.variables[i]][100:end]) .* 100, 129600)
            lines!(trend; label = only(unique(gdf[j].shock)))
        end
        ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
    end

    ax1 = fig.content[1]; ax2 = fig.content[2]; ax3 = fig.content[3];
    ax4 = fig.content[4]; ax5 = fig.content[5]; ax6 = fig.content[6];
    ax7 = fig.content[7]; ax8 = fig.content[8]; ax9 = fig.content[9]

    ax1.ylabel = ax4.ylabel = ax7.ylabel = "Growth rate (%)"
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
    
    vars = (variables = [:ON_liabs, :Term_liabs, :deposit_facility, :lending_facility], 
        labels = ["Overnight segment", "Term segment", "Deposit facility", "Lending Facility"])   
            
    for i in 1:length(vars.variables)   
        ax = fig[axes[i]...] = Axis(fig, title = vars.labels[i])
        for j in 2:length(gdf)
            _, trend = hp_filter(((gdf[j][!, vars.variables[i]][100:end] .- gdf[1][!, vars.variables[i]][100:end])./gdf[1][!, vars.variables[i]][100:end]) .* 100, 129600)
            lines!(trend; label = only(unique(gdf[j].shock)))
        end
        ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
    end

    ax1 = fig.content[1]; ax2 = fig.content[2]; ax3 = fig.content[3];  ax4 = fig.content[4]; 
   

    ax1.ylabel = "Growth rate (%)"
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
        for j in 2:length(gdf)
           _, base_trend = hp_filter((1 .- gdf[1][!, vars.variables_num[i]][100:end] ./ gdf[1][!, vars.variables_den[i]][100:end]), 129600)
            _, trend = hp_filter((1 .- gdf[j][!, vars.variables_num[i]][100:end] ./ gdf[j][!, vars.variables_den[i]][100:end]) ./ base_trend, 129600)
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

function big_ib_by_status(df)
    fig = Figure(resolution = (1200, 300), fontsize = 10)
    axes = ((1,1), (1,2), (1,3))

    gdf = @pipe df |> 
        groupby(_, :shock)
    
    vars = (variables = [:margin_stability, :am, :bm], 
        labels = ["Margin of stability", "ASF", "RSF"])   
        
    for i in 1:length(vars.variables)   
        ax = fig[axes[i]...] = Axis(fig, title = vars.labels[i])
        for j in 2:length(gdf)
            _, trend = hp_filter((gdf[j][!, vars.variables[i]][100:end]) ./ gdf[1][!, vars.variables[i]][100:end], 129600)
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

function flow_plots(df)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Payment flows", xlabel = "Steps", ylabel = "Growth rates (%)")
    gdf = @pipe df |>
        groupby(_, :shock)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.flow_growth[100:end]), 129600)
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

function theta_lbw(df)
    fig = Figure(resolution = (800, 400), fontsize = 10)
    axes = ((1,1), (1,2))
    gdf = @pipe df |> 
        groupby(_, :shock)
    
    vars = (variables = [:θ, :LbW], 
        labels = [L"θ", L"L_{b}W"])   
            
    for i in 1:length(vars.variables)   
        ax = fig[axes[i]...] = Axis(fig, title = vars.labels[i])
        for j in 2:length(gdf)
            _, trend = hp_filter((gdf[j][!, vars.variables[i]][100:end]) ./ gdf[1][!, vars.variables[i]][100:end], 129600)
            lines!(trend; label = only(unique(gdf[j].shock)))
        end
        ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
    end

    ax1 = fig.content[1]; ax2 = fig.content[2]

    ax1.ylabel = ax2.ylabel = "Growth rate (%)"
    ax1.xlabel = ax2.xlabel  = "Steps"
   
    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )

    return fig
end

function interest_ib(df)
    fig = Figure(resolution = (800, 400), fontsize = 10)
    axes = ((1,1), (1,2))
    gdf = @pipe df |> 
        groupby(_, :shock)
    
    vars = (variables = [:ion, :iterm], 
        labels = ["ON rate", "Term rate"])   
            
    for i in 1:length(vars.variables)   
        ax = fig[axes[i]...] = Axis(fig, title = vars.labels[i])
        for j in 2:length(gdf)
            _, trend = hp_filter((gdf[j][!, vars.variables[i]][100:end]) ./ gdf[1][!, vars.variables[i]][100:end], 129600)
            lines!(trend; label = only(unique(gdf[j].shock)))
        end
        ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
    end

    ax1 = fig.content[1]; ax2 = fig.content[2]

    ax1.ylabel = ax2.ylabel = "Growth rate (%)"
    ax1.xlabel = ax2.xlabel  = "Steps"
   
    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )
    return fig
end

function credit_rates(df)
    fig = Figure(resolution = (800, 400), fontsize = 10)
    axes = ((1,1), (1,2))
    gdf = @pipe df |> 
        groupby(_, :shock)
    
    vars = (variables = [:il_rate, :id_rate], 
        labels = ["Loans rate", "Deposits rate"])   
            
    for i in 1:length(vars.variables)   
        ax = fig[axes[i]...] = Axis(fig, title = vars.labels[i])
        for j in 2:length(gdf)
            _, trend = hp_filter((gdf[j][!, vars.variables[i]][100:end]) ./ gdf[1][!, vars.variables[i]][100:end], 129600)
            lines!(trend; label = only(unique(gdf[j].shock)))
        end
        ax.xticks = (collect(100:200:1200), ["200", "400", "600", "800", "1000", "1200"])
    end

    ax1 = fig.content[1]; ax2 = fig.content[2]

    ax1.ylabel = ax2.ylabel = "Growth rate (%)"
    ax1.xlabel = ax2.xlabel  = "Steps"
   
    fig[end+1,1:2] = Legend(fig, 
        ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )

    return fig
end