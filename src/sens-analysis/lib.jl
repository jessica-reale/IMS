fontsize_theme = Theme(fontsize = 24, font = :bold_italic)
attributes = Attributes(
    Axis = (
        xgridvisible = false,
        ygridvisible = false,
        ytickalign = 1,
        xtickalign = 1,
    ),
)
set_theme!(merge(fontsize_theme, attributes))

const IB_STATUS = ("deficit", "surplus")
const SHIFT = 100

function credit_loans(df::DataFrame, param::Symbol; f::Bool = true)
    fig = Figure(resolution = (900, 450), fontsize = 16)
    ax = fig[1,1] = Axis(fig, xlabel = "Steps", ylabel = "Moving Average")
    gdf = groupby(df, param)

    for i in 1:length(gdf)
        _, trend = hp_filter((gdf[i].loans[100:end]), 129600)
        lines!(movavg(trend, 200).x; 
            label = "$(param) = $(only(unique(gdf[i][!, param])))", linewidth = 2,
            linestyle = 
                if i > length(Makie.wong_colors())
                    :dash
                end             
        )
    end

     # Set x-axis ticks
    ax.xticks = SHIFT:300:1200
    ax.title = if f 
        "Firms Loans"
        else
            "Households Loans"
        end

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :vertical,
        nbanks = 4)

    return fig
end

function output(df::DataFrame, param::Symbol)
    fig = Figure(resolution = (900, 450), fontsize = 16)
    ax = fig[1,1] = Axis(fig, title = L"\text{GDP}", xlabel = L"\text{Steps}", ylabel = L"\text{Moving Average}")
    gdf = groupby(df, param)

    for i in 1:length(gdf)
        _, trend = hp_filter((gdf[i].output[100:end]), 129600)
        lines!(movavg(trend, 200).x; 
            label = "$(param) = $(only(unique(gdf[i][!, param])))", linewidth = 2,
            linestyle = 
                if i > length(Makie.wong_colors())
                    :dash
                end
        )
    end

    # Set x-axis ticks
    ax.xticks = SHIFT:300:1200
    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :vertical,
        nbanks = 4)

    return fig
end

function flow(df::DataFrame, param::Symbol)
    fig = Figure(resolution = (900, 450), fontsize = 16)
    axes = ((1,1), (1,2))
    gdf = groupby(df, param)

    for i in eachindex(IB_STATUS)
        ax = fig[axes[i]...] = Axis(fig, title =  IB_STATUS[i])
        for j in 1:length(gdf)
            sdf = filter(r -> r.status == IB_STATUS[i], gdf[j])
            _, trend = hp_filter(sdf[!, :flow][100:end], 129600)
            lines!(movavg(trend, 200).x; linewidth = 2,
                label = "$(param) = $(only(unique(gdf[j][!, param])))", 
                linestyle = 
                    if j > length(Makie.wong_colors())
                        :dash
                    end
            )
        end
        # Set x-axis ticks
        ax.xticks = SHIFT:300:1200    
    end

    ax1 = fig.content[1]; ax2 = fig.content[2]
    ax1.ylabel = L"\text{Moving Average}"
    ax1.xlabel = ax2.xlabel  = L"\text{Steps}"

    fig[end + 1, 1:2] = Legend(fig, ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :vertical,
        nbanks = 4)

    return fig
end

function stability(df::DataFrame, param::Symbol)
    fig = Figure(resolution = (900, 450), fontsize = 16)
    axes = ((1,1), (1,2))
    gdf = groupby(df, param)

    for i in eachindex(IB_STATUS)
        ax = fig[axes[i]...] = Axis(fig, title =  IB_STATUS[i])
        for j in 1:length(gdf)
            sdf = filter(r -> r.status == IB_STATUS[i], gdf[j])
            _, trend = 
                if sdf.status == IB_STATUS[1]
                    hp_filter(sdf[!, :am][100:end], 129600)
                else
                    hp_filter(1 .- sdf[!, :margin_stability][100:end], 129600)
                end
                
            lines!(movavg(trend, 200).x; linewidth = 2,
                label = "$(param) = $(only(unique(gdf[j][!, param])))", 
                linestyle = 
                    if j > length(Makie.wong_colors())
                        :dash
                    end
            )
        end
        # Set x-axis ticks
        ax.xticks = SHIFT:300:1200   
    end

    ax1 = fig.content[1]; ax2 = fig.content[2]
    ax1.ylabel = L"\text{Moving Average}"
    ax1.xlabel = ax2.xlabel  = L"\text{Steps}"

    fig[end + 1, 1:2] = Legend(fig, ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :vertical,
        nbanks = 4)

    return fig
end

function big_ib_plots_sens(df::DataFrame, param::Symbol)
    fig = Figure(resolution = (1200, 400), fontsize = 16)
    axes = ((1,1), (1,2), (1,3), (1,4))
    gdf = @pipe df |> 
        groupby(_, param)
    
    vars = (variables = [:Term_liabs, :ON_liabs, :lending_facility, :deposit_facility], 
        labels = [L"\text{Term segment}", L"\text{Overnight segment}", L"\text{Lending Facility}", L"\text{Deposit facility}"])     
            
    for i in 1:length(vars.variables)   
        ax = fig[axes[i]...] = Axis(fig, title = vars.labels[i])
        for j in 1:length(gdf)
            _, trend = hp_filter(gdf[j][!, vars.variables[i]][100:end], 129600)
            lines!(trend; label = "$(param) = $(only(unique(gdf[j][!, param])))", linewidth = 2,
                linestyle = 
                    if j > length(Makie.wong_colors())
                        :dash
                    end
            )
        end
        # Set x-axis ticks
        ax.xticks = SHIFT:300:1200    
    end

    ax1 = fig.content[1]; ax2 = fig.content[2]; ax3 = fig.content[3];  ax4 = fig.content[4]; 
    ax1.ylabel = L"\text{Moving Average}"
    ax1.xlabel = ax2.xlabel = ax3.xlabel = ax4.xlabel = L"\text{Steps}"

    fig[end+1,1:4] = Legend(fig, ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :vertical,
        nbanks = 4)
    return fig 
end

function stability_ib_plots_sens(df::DataFrame, param::Symbol)
    fig = Figure(resolution = (1200, 600), fontsize = 16)
    axes = ((1:2,1), (1,2), (1,3), (2,2), (2,3))
    gdf = @pipe df |> 
        groupby(_, param)
    
    vars = (variables = [:margin_stability, :am, :bm, :pmb, :pml], 
        labels = [L"\text{Margin of stability}", L"\text{ASF} a_{m}", L"\text{RSF} b_{m}",
            L"\Pi^{b}", L"\Pi^{l}"])
            
    for i in 1:length(vars.variables)   
        ax = fig[axes[i]...] = Axis(fig, title = vars.labels[i])
        for j in 1:length(gdf)
            _, trend = hp_filter((gdf[j][!, vars.variables[i]][100:end]), 129600)
            lines!(movavg(trend, 200).x; label = "$(param) = $(only(unique(gdf[j][!, param])))", linewidth = 2,
                linestyle = 
                    if j > length(Makie.wong_colors())
                        :dash
                    end
            )
        end
        # Set x-axis ticks
        ax.xticks = SHIFT:300:1200   
    end

    ax1 = fig.content[1]; 
    ax2 = fig.content[2]; ax3 = fig.content[3];
    ax4 = fig.content[4]; ax5 = fig.content[5];
    ax1.ylabel = ax2.ylabel = ax4.ylabel = L"\text{Moving Average}"
    ax1.xlabel = ax4.xlabel = ax5.xlabel = L"\text{Steps}"
    ax2.xticklabelsvisible = ax3.xticklabelsvisible = false
    ax2.xticksvisible = ax3.xticksvisible = false
    ax1.ytickformat = ax2.ytickformat = "{:.3f}"

    fig[end+1,1:3] = Legend(fig, ax1; 
        tellheight = true, 
        tellwidth = false,
        orientation = :vertical,
        nbanks = 4)
    return fig
end

function big_params(df::DataFrame, var::Symbol, params::Vector{Symbol})
    fig = Figure(resolution = (1200, 600), fontsize = 16)
    axes = ((1:2,1), (1,2), (1,3), (2,2), (2,3))
            
    for i in 1:length(params[2:end])
        ax = fig[axes[i]...] = Axis(fig, title = string.(params[2:end][i]))
        gdf = @pipe df |> filter(params[2:end][i] => x -> !ismissing(x), _) |>
            groupby(_, params[2:end][i])
        for j in 1:length(gdf)
            _, trend = hp_filter((gdf[j][!, var][100:end]), 129600)
            lines!(movavg(trend, 200).x; label = "$(string.(params[2:end][i])) = $(only(unique(gdf[j][!, params[2:end][i]])))", linewidth = 2,
                linestyle = 
                    if j > length(Makie.wong_colors())
                        :dash
                    end
            )
        end
        # Set x-axis ticks
        ax.xticks = SHIFT:300:1200    
    end

    ax1 = fig.content[1]; 
    ax2 = fig.content[2]; ax3 = fig.content[3];
    ax4 = fig.content[4]; ax5 = fig.content[5];
    ax1.ylabel = ax2.ylabel = ax4.ylabel = L"\text{Moving Average}"
    ax1.xlabel = ax4.xlabel = ax5.xlabel = L"\text{Steps}"
    ax2.xticklabelsvisible = ax3.xticklabelsvisible = false
    ax2.xticksvisible = ax3.xticksvisible = false
    
    axislegend(ax1; position = (1.0, 0.93))
    axislegend(ax2; position = (1.0, 0.93))
    axislegend(ax3; position = (1.0, 0.93))
    axislegend(ax4; position = (1.0, 0.93))
    axislegend(ax5; position = (1.0, 0.93))
    return fig
end

function create_tables(df::DataFrame, parameter::Symbol)
    df = @pipe df |>  dropmissing(_, vars) |>
        filter(r -> r.status != "neutral", _) |> 
        groupby(_, parameter) |>
        combine(_, [:ON_liabs, :Term_liabs] .=> mean, [:ON_liabs, :Term_liabs] .=> std, renamecols = true) |>
        filter(parameter => x -> !ismissing(x))

    # Add standard deviation values in parentheses below the mean values
    df[:, :ON_liabs] = string.(round.(df.ON_liabs_mean; digits = 4), " (", df.ON_liabs_std, ")")
    df[:, :Term_liabs] = string.(round.(df.Term_liabs_mean; digits = 4), " (", df.Term_liabs_std, ")")
    df[:, :param] = string.(df[!, parameter])

    # Remove standard deviation and mean columns as they are now merged
    select!(df, Not([:ON_liabs_mean, :Term_liabs_mean, :ON_liabs_std, :Term_liabs_std, parameter]))

    # Define a new DataFrame for LaTeX output
    latex_df = DataFrame(
        value = String[],
        ON_volumes = String[],
        Term_volumes = String[]
    )

    # Iterate through the DataFrame to populate the LaTeX DataFrame
    last_param = ""
    for i in 1:size(df, 1)
        param = df[i, :param]
        # If the shock is the same as the last one, use \multirow and empty string for repeated shock
        if param == last_param
            push!(latex_df, ["", df[i, :ON_liabs], df[i, :Term_liabs]])
        else
            push!(latex_df, [param,  df[i, :ON_liabs], df[i, :Term_liabs]])
        end
        last_param = param
    end

    latex_code = "\\begin{tabular}{|c||c|c|}\n"
    latex_code *= "\\hline\n"
    latex_code *= "Value $(parameter) & ON volumes & Term volumes \\\\\n"
    latex_code *= "\\hline\n"

    for i in 1:size(df, 1)
        if i > 1 && df[i, :param] == df[i-1, :param]
            latex_code *=  extract_number_before_parentheses(df[i, :ON_liabs]) * " & " * extract_number_before_parentheses(df[i, :Term_liabs]) * " \\\\\n"
            #latex_code *= "&" * extract_number_with_parentheses(df[i, :ON_liabs]) * " & " * extract_number_with_parentheses(df[i, :Term_liabs]) * " \\\\\n"
        else
            rowspan = sum(df[:, :param] .== df[i, :param])
            latex_code *= "\\multirow{" * string(rowspan) * "}{*}{" * df[i, :param] * "} & "
            latex_code *= extract_number_before_parentheses(df[i, :ON_liabs]) * " & " * extract_number_before_parentheses(df[i, :Term_liabs]) * " \\\\\n"
            #latex_code *= "&" * extract_number_with_parentheses(df[i, :ON_liabs]) * " & " * extract_number_with_parentheses(df[i, :Term_liabs]) * " \\\\\n"
        end
    end
    
    latex_code *= "\\hline\n"
    latex_code *= "\\end{tabular}"
    return latex_code
end

function extract_number_before_parentheses(str::String)
    m = match(r"^([^\s]+) \(", str)
    return m !== nothing ? m.captures[1] : nothing
end

function extract_number_with_parentheses(str::String)
    m = match(r"(\([^\)]+\))", str)
    return m !== nothing ? m.captures[1] : nothing
end
