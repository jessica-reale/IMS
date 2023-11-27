include("utils.jl")

# define constants to be used in plots generation
const SHIFT = 100
const BY_STATUS = ("deficit", "surplus")
const SHOCKS = ("Missing", "Corridor", "Width", "Uncertainty")
const colors = Gray.([0.0, 0.2, 0.4, 0.6, 0.8])

# generate plots
function generate_plots(df::DataFrame, vars::Vector{Symbol};
    # keywords arguments
    vars_den = Symbol[],
    ylabels = String[], 
    labels = String[],
    rationing = false, 
    area = false, 
    status = false, 
    by_vars = false, 
    loans = false, 
    rows = false)

    # Group df by shock
    gdf = groupby(df, :shock)
    
    # Define resolution depending on type of plots
    resol = rows ? (1500, 800) : (1200, 400)

    # Define custom length of axes according to type of plot
    custom_length() = (by_vars || rationing) ? length(vars) : (status ? length(BY_STATUS) : length(gdf))

    # Define figure resolution
    fig = Figure(resolution = resol)

    # Generate Plots
    if rationing
        if !rows
            plots_vars_shocks(fig, gdf, vars, ylabels; double = (rationing = rationing, vars_den = vars_den))
        elseif rows
            plots_vars_shocks_rows(fig, gdf, vars, ylabels; double = (rationing = rationing, vars_den = vars_den))
        end
    elseif status
        if !rows
            plots_group(fig, gdf, vars, ylabels; loans)
        elseif rows
            plots_group_rows(fig, gdf, vars, ylabels; loans)
        end
    elseif area
        plots_area(fig, df, vars, labels) # groupby within plots_area function
    elseif by_vars
        if !rows
            plots_vars_shocks(fig, gdf, vars, ylabels)
        elseif rows
            plots_vars_shocks_rows(fig, gdf, vars, ylabels)
        end
    else
        plots_shock_vars(fig, gdf, vars, labels)
    end

    # Add Legend for labels
    if !isempty(union(labels, ylabels)) && !rows
        fig[end+1,1:custom_length()] = Legend(
            fig,
            fig.content[1];
            tellheight = true,
            tellwidth = false,
            orientation = :horizontal
        )
    end
    return fig
end

function plots_shock_vars(fig, gdf, vars, labels)
    # Iterate over each gdf
    for i in 1:length(gdf)
        # Define axes positions
        axes = tuple(collect((1, i) for i in 1:length(gdf))...)
        ax = fig[axes[i]...] = Axis(fig, title = SHOCKS[i])
        
        for j in 1:length(vars)
            # Apply HP filter to the selected variable
            cycle, trend = hp_filter(gdf[i][!, vars[j]][SHIFT:end], 129600)

            # Plot the main trend line with labels
            lines!(trend; label = labels[j], linewidth = 2)

            # Plot standard deviation bands
            standard_deviation_bands!(cycle, trend, Makie.wong_colors()[j])

            fig.content[1].ylabel =  "Mean"
            fig.content[i].xlabel = "Steps"

            # Add dotted lines to the plot
            add_lines!(gdf[i])
        end
       
        # Set x-axis ticks
        ax.xticks = SHIFT:300:1200
    end
end

function plots_area(fig, df, vars, labels)
    # Filter out "neutral" status in the DataFrame
    df = filter(:status_unique => x -> x != "neutral", df)
    
    # Group the filtered DataFrame by "status"
    gdf = groupby(df, :status_unique)

    # Iterate over each shock in SHOCKS
    for i in eachindex(SHOCKS)
        # Define axes positions
        axes = tuple(collect((1, i) for i in 1:length(SHOCKS))...)
        # Create an axis for the current shock
        ax = fig[axes[i]...] = Axis(fig, title = SHOCKS[i], ytickformat = "{:.1f}")
        
        # Iterate over each group of data in gdf
        for j in 1:length(gdf)
            # Filter the data for the current shock
            sdf = filter(r -> r.shock == SHOCKS[i], gdf[j])
            
            # Apply HP filter to the selected variable
            _, trend = hp_filter(sdf[!, vars[1]][SHIFT:end], 129600)
            
            # Create a shaded band for the area
            band!(sdf.step[SHIFT:end] .- SHIFT, min.(trend) .+ mean.(trend) .+ std(trend), 
                max.(trend) .- mean.(trend) .- std(trend); label = labels[j])
            
            # Set axis labels
            fig.content[1].ylabel = "Mean"
            fig.content[i].xlabel = "Steps"
        end
        
        # Hide y-axis labels
        invisible_yaxis!(fig, i)
        
        # Set x-axis ticks
        ax.xticks = SHIFT:300:1200
    end
    
    # Link the y-axes for all subplots
    linkyaxes!(fig.content...)
end

function plots_vars_shocks(fig, gdf, vars, ylabels; 
    double::NamedTuple{(:rationing, :vars_den), Tuple{Bool, Vector{Symbol}}} = (rationing = false, vars_den = Symbol[]))

    for i in 1:length(vars)
        ax = fig[1, i] = Axis(fig, title = ylabels[i])
        for j in 1:length(gdf)
            # Apply HP filter to the selected variable
            cycle, trend = if !double.rationing
                    hp_filter(gdf[j][!, vars[i]][SHIFT:end], 129600)
                else
                    hp_filter((1 .- gdf[j][!, vars[i]][SHIFT:end] ./ gdf[j][!, double.vars_den[i]][SHIFT:end]) .* 100, 129600)
                end

            # Plot the main trend line
            lines!(trend; linewidth = 2, label = only(unique(gdf[j].shock)))

            # Add standard deviation lines
            standard_deviation_bands!(cycle, trend, Makie.wong_colors()[j])
            
            # Set ticks x-axys
            ax.xticks = SHIFT:300:1200
            fig.content[1].ylabel = !double.rationing ? "Mean" : "Rate (%)"
            fig.content[i].xlabel = "Steps"
        end
    end
end

function plots_group(fig, gdf, vars, ylabels; loans::Bool = false)
    for i in eachindex(BY_STATUS)
        ax = fig[1 , i] = Axis(fig, title = ylabels[i])
        for j in 1:length(gdf)
            # Filter the data for the current status
            sdf = filter(r -> r.status_unique == BY_STATUS[i], gdf[j])

            # Apply HP filter to the selected variable
            cycle, trend = hp_filter(sdf[!, vars[length(vars)]][SHIFT:end], 129600)

            # Plot the main trend line
            lines!(trend; linewidth = 2, label = only(unique(gdf[j].shock)))

            # Add standard deviation lines
            standard_deviation_bands!(cycle, trend, Makie.wong_colors()[j])

            # Set ticks x-axys
            ax.xticks = SHIFT:300:1200
            fig.content[1].ylabel =  "Mean"
            fig.content[i].xlabel = "Steps"
            if loans
                linkyaxes!(fig.content...)
                invisible_yaxis!(fig, i)
            end
        end
    end
end

# Alternative plots, one variable per row 
function plots_vars_shocks_rows(fig, gdf, vars, ylabels; 
    double::NamedTuple{(:rationing, :vars_den), Tuple{Bool, Vector{Symbol}}} = (rationing = false, vars_den = Symbol[]))

    for i in 1:length(vars)
        for j in 1:length(gdf)
            axes = (i, j)
            ax = fig[axes...] = Axis(fig, title = only(unique(gdf[j].shock)))

            # Apply HP filter to the selected variable
            cycle, trend = if !double.rationing
                    hp_filter(gdf[j][!, vars[i]][SHIFT:end], 129600)
                else
                    hp_filter((1 .- gdf[j][!, vars[i]][SHIFT:end] ./ gdf[j][!, double.vars_den[i]][SHIFT:end]) .* 100, 129600)
                end

            # Plot the main trend line
            lines!(trend; color = :black, linewidth = 2)

            # Add standard deviation lines
            standard_deviation_bands!(cycle, trend, :black)
            
            # Set ticks x-axys
            ax.xticks = SHIFT:300:1200
            fig.content[i].xlabel = "Steps"
        end
    end
    # Set Axes features
    set_axes!(fig, gdf, vars, ylabels)
end

function plots_group_rows(fig, gdf, vars, ylabels; loans::Bool = false)
    for i in eachindex(BY_STATUS)
        for j in 1:length(gdf)
            axes = (i, j)
            ax = fig[axes...] = Axis(fig, title = only(unique(gdf[j].shock)))

            # Filter the data for the current status
            sdf = filter(r -> r.status_unique == BY_STATUS[i], gdf[j])

            # Apply HP filter to the selected variable
            cycle, trend = hp_filter(sdf[!, vars[length(vars)]][SHIFT:end], 129600)

            # Plot the main trend line
            lines!(trend; color = :black, linewidth = 2)

            # Add standard deviation lines
            standard_deviation_bands!(cycle, trend, :black)

            # Set ticks x-axys
            ax.xticks = SHIFT:300:1200
            fig.content[i].xlabel = "Steps"
            if loans
                linkyaxes!(fig.content...)
                invisible_yaxis!(fig, i)
            end
        end
    end
    # Set Axes features
    set_axes!(fig, gdf, vars, ylabels; status = true)
end

# Generate tables
# Create LaTeX table for the Appendix - standard deviations
function create_table(df::DataFrame, var::Symbol, scenario::String, var_name::String)
    gdf = @pipe df |> dropmissing(_, vars_ib) |> 
        groupby(_, [:shock, :scenario, :status, :ib_flag, :step, :sample_size]) |>
        combine(_, vars_ib .=> mean, renamecols = false) |>
        filter(r -> r.shock == "Missing" && r.scenario == scenario && r.status == "deficit" && r.ib_flag == true, _) |> 
        groupby(_, :sample_size)

    # Calculate mean, standard deviation, and standard error for each group
    results = DataFrame(sample_size = Int[], mean_var = String[], std_var = Float64[], se_var = Float64[])
    for sdf in gdf
        cycle, trend = hp_filter(sdf[!, var], 129600)
        residuals = cycle - trend
        mean_val = mean(trend)
        std_val = std(residuals)
        current_sample_size = unique(sdf.sample_size)[1]
        se_val = std_val / sqrt(current_sample_size)
        t_value = abs(mean_val / se_val)

        # compute significance using the t-distribution
        degrees_freedom = current_sample_size - 1  # degrees of freedom
        t_critical_1_percent = quantile(TDist(degrees_freedom), 0.995)  # two-tailed test at 0.01 level
        t_critical_5_percent = quantile(TDist(degrees_freedom), 0.975)  # two-tailed test at 0.05 level

        # Determine significance and asterisks
        if t_value > t_critical_1_percent
            significance = "***"
        elseif t_value > t_critical_5_percent
            significance = "**"
        else
            significance = ""
        end

        mean_str = "$(round(mean_val, digits=2))$(significance)" # Formatting mean value with significance asterisks
        push!(results, (sample_size=current_sample_size, mean_var=mean_str, std_var=std_val, se_var=se_val))
    end

    # Create the LaTeX table
    latex_table = """
    \\begin{table}
    \\centering
    \\begin{tabular}{|c|c|c|c|}
    \\hline
    Number of Runs & Mean & Standard Deviation & Standard Error\\\\
    \\hline
    """

    for row in eachrow(results)
        latex_table *= "$(row.sample_size) & $(row.mean_var) & $(row.std_var) & $(row.se_var)\\\\\\hline\n"
    end

    latex_table *= "\\end{tabular}\n\\caption{Mean, Standard Deviation, and Standard Error of $(var_name) for Different Numbers of Runs -  $(scenario)-scenario.}\n\\end{table" 
    return latex_table
end

function create_table_slides(df::DataFrame)
    df = @pipe df |>  dropmissing(_, vars_ib) |>
        filter([:sample_size, :status_unique] => (x, y) -> x == 100 && y != "neutral", _) |> 
        groupby(_, [:shock, :scenario]) |>
        combine(_, [:ON_liabs_mean, :Term_liabs_mean] .=> mean, [:ON_liabs_mean, :Term_liabs_mean] .=> std, renamecols = true)

    # Add standard deviation values in parentheses below the mean values
    df[:, :ON_liabs] = string.(df.ON_liabs_mean_mean, " (", df.ON_liabs_mean_std, ")")
    df[:, :Term_liabs] = string.(df.Term_liabs_mean_mean, " (", df.Term_liabs_mean_std, ")")

    # Remove standard deviation and mean columns as they are now merged
    select!(df, Not([:ON_liabs_mean_mean, :Term_liabs_mean_mean, :ON_liabs_mean_std, :Term_liabs_mean_std]))

    # Define a new DataFrame for LaTeX output
    latex_df = DataFrame(
        Shock = String[],
        Scenario = String[],
        ON_volumes = String[],
        Term_volumes = String[]
    )

    # Iterate through the DataFrame to populate the LaTeX DataFrame
    last_shock = ""
    for i in 1:size(df, 1)
        shock = df[i, :shock]
        # If the shock is the same as the last one, use \multirow and empty string for repeated shock
        if shock == last_shock
            push!(latex_df, ["", df[i, :scenario], df[i, :ON_liabs], df[i, :Term_liabs]])
        else
            push!(latex_df, [shock, df[i, :scenario], df[i, :ON_liabs], df[i, :Term_liabs]])
        end
        last_shock = shock
    end

    latex_code = "\\begin{tabular}{llll}\n"
    latex_code *= "\\hline\n"
    latex_code *= "Shock & Scenario & ON volumes & Term volumes \\\\\n"
    latex_code *= "\\hline\n"

    for i in 1:size(df, 1)
        if i > 1 && df[i, :shock] == df[i-1, :shock]
            latex_code *= "& " * df[i, :scenario] * " & " * extract_number_before_parentheses(df[i, :ON_liabs]) * " & " * extract_number_before_parentheses(df[i, :Term_liabs]) * " \\\\\n"
            latex_code *= "& " * "& " * extract_number_with_parentheses(df[i, :ON_liabs]) * " & " * extract_number_with_parentheses(df[i, :Term_liabs]) * " \\\\\n"
        else
            rowspan = sum(df[:, :shock] .== df[i, :shock])
            latex_code *= "\\multirow{" * string(rowspan) * "}{*}{" * df[i, :shock] * "} & "
            latex_code *= df[i, :scenario] * " & " * extract_number_before_parentheses(df[i, :ON_liabs]) * " & " * extract_number_before_parentheses(df[i, :Term_liabs]) * " \\\\\n"
            latex_code *= "& " * "& " * extract_number_with_parentheses(df[i, :ON_liabs]) * " & " * extract_number_with_parentheses(df[i, :Term_liabs]) * " \\\\\n"
        end
    end
    
    latex_code *= "\\hline\n"
    latex_code *= "\\end{tabular}"
    return latex_code
end