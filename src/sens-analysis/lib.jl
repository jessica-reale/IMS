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
const COLORS = Gray.([0.75, 0.5, 0.25])

function standard_deviation_bands!(cycle, trend, colors)
    # Compute residuals from cyclicality of the time series
    residuals = cycle - trend
    # Compute the standard deviation of the residuals
    sigma = std(residuals)
    # Calculate upper and lower bands
    upper_bound = trend .+ sigma
    lower_bound = trend .- sigma

    # Plot the standard deviations as dashed lines
    lines!(lower_bound; color = (colors, 0.3), linestyle = :dash)
    lines!(upper_bound; color = (colors, 0.3), linestyle = :dash)
end

function compute_std(df, var::Symbol)
    cycle, trend = hp_filter(df[!, var], 129600)
    residuals =  cycle - trend
    mean_val = mean(trend)
    std_val = std(residuals)

    return mean_val, std_val
end

function extract_number_before_parentheses(str::String)
    m = match(r"^([^\s]+) \(", str)
    return m !== nothing ? m.captures[1] : nothing
end

function extract_number_with_parentheses(str::String)
    m = match(r"(\([^\)]+\))", str)
    return m !== nothing ? m.captures[1] : nothing
end

# Create plots for generic parameters 
function big_params(df::DataFrame, var::Symbol, params::Vector{Symbol})
    fig = Figure(resolution = (1200, 600), fontsize = 16)
    axes = ((1:2,1), (1,2), (1,3), (2,2), (2,3))
            
    for i in 1:length(params[2:end])
        ax = fig[axes[i]...] = Axis(fig, title = string.(params[2:end][i]))
        gdf = @pipe df |> filter(params[2:end][i] => x -> !ismissing(x), _) |>
            groupby(_, params[2:end][i])
        for j in 1:length(gdf)
            cycle, trend = hp_filter((gdf[j][!, var][100:end]), 129600)
            lines!(trend; label = "$(string.(params[2:end][i])) = $(only(unique(gdf[j][!, params[2:end][i]])))", linewidth = 2,
                linestyle = 
                    if j > length(Makie.wong_colors())
                        :dash
                    end,
                color = COLORS[j]
            )
            
            # Add standard deviation lines
            standard_deviation_bands!(cycle, trend, COLORS[j])
        
        end
        # Set x-axis ticks
        ax.xticks = SHIFT:300:1200    
    end

    ax1 = fig.content[1]; 
    ax2 = fig.content[2]; ax3 = fig.content[3];
    ax4 = fig.content[4]; ax5 = fig.content[5];
    ax1.ylabel = ax2.ylabel = ax4.ylabel = L"\text{Mean}"
    ax1.xlabel = ax4.xlabel = ax5.xlabel = L"\text{Steps}"
    ax2.xticklabelsvisible = ax3.xticklabelsvisible = false
    ax2.xticksvisible = ax3.xticksvisible = false
    
    axislegend(ax1; position = (1.0, 0.93))
    axislegend(ax2; position = (1.0, 0.93))
    axislegend(ax3; position = (1.0, 0.1))
    axislegend(ax4; position = (1.0, 0.93))
    axislegend(ax5; position = (1.0, 0.1))
    return fig
end

# Create tables for NSFR parameters
function create_tables(df::DataFrame, parameters::Vector{Symbol})
    # Initialize the results DataFrame
    results = DataFrame(Parameter = String[], Range = String[], ON_volumes = String[], Term_volumes = String[])

    # Iterate over each parameter and compute statistics
    for parameter in parameters
        gdf = @pipe df |> dropmissing(_, vars_ib) |> dropmissing(_, parameter) |> filter(r -> r.ib_flag == true && r.status != "neutral", _) |> 
            groupby(_, [:status, :step, parameter]) |>
            combine(_, vars_ib .=> mean, renamecols = false) |>
            groupby(_, parameter)

        for i in 1:length(gdf)
            mean_ON, std_ON = compute_std(gdf[i], :ON_liabs)
            mean_Term, std_Term = compute_std(gdf[i], :Term_liabs)
            range_value = string(only(unique(gdf[i][!, parameter])))

            push!(results, (Parameter = string(parameter), Range = range_value, 
                                ON_volumes = string(round(mean_ON, digits = 4), " (", round(std_ON, digits = 4), ")"), 
                                Term_volumes = string(round(mean_Term, digits = 4), " (", round(std_Term, digits = 4), ")")))
        end
    end

    # Begin constructing LaTeX table with the dynamic header based on the number of parameters
    latex_code = "\\begin{tabular}{|c"
    for _ in 1:length(parameters)
        latex_code *= "||c|c"  # Two columns for each parameter
    end
    latex_code *= "|}\n\\hline\n"

    # Header row with parameter names
    latex_code *= " & "
    for (i, parameter) in enumerate(parameters)
        separator = i < length(parameters) ? " & " : " \\\\ \\cline{2-$(2*length(parameters)+1)}\n"
        latex_code *= "\\multicolumn{2}{c||}{$(string(parameter))}" * separator
    end

    # Sub-header row with 'ON volumes' and 'Term volumes'
    latex_code *= "Range "
    for _ in 1:length(parameters)
        latex_code *= "& ON volumes & Term volumes "
    end
    latex_code = latex_code[1:end-1] * "\\\\ \\hline\n"

    # Loop over each unique range value in the results DataFrame
    unique_ranges = unique(results.Range)
    for range_value in unique_ranges
        latex_code *= range_value
        
        # For each parameter within this range, add the ON volumes and Term volumes
        for parameter in parameters
            # Find the row for the current parameter and range value
            row = filter(r -> r.Parameter == string(parameter) && r.Range == range_value, results)

            if !isempty(row)
                row = first(row)
                latex_code *= "& " * row.ON_volumes * " & " * row.Term_volumes # * "\\\\ \n"
                #latex_code *= "&" * extract_number_with_parentheses(row[:ON_volumes]) * "&" * extract_number_with_parentheses(row[:Term_volumes])
            else
                # Fill with placeholders if no data is present
                latex_code *= "& - & -"
            end
        end

        latex_code *= "\\\\ \\hline\n"
    end

    latex_code *= "\\end{tabular}"
    return latex_code
end
