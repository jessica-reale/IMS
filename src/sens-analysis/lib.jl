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
function create_tables(df::DataFrame, parameter::Symbol)
    gdf = @pipe df |> dropmissing(_, vars_ib) |> 
        filter(parameter => x -> !ismissing(x)) |> 
        groupby(_, parameter)

    # Calculate mean, standard deviation, and standard error for each group
    results = DataFrame(Parameter = String[], ON_volumes = String[], Term_volumes = String[])
    for sdf in gdf
        mean_ON, std_ON = compute_std(sdf, :ON_liabs)
        mean_Term, std_Term = compute_std(sdf, :Term_liabs)

        push!(results, (Parameter = string(only(unique(sdf[!, parameter]))), ON_volumes = string(round.(mean_ON; digits = 4), " (", std_ON, ")"), 
            Term_volumes = string(round.(mean_Term; digits = 4), " (", std_Term, ")")))
    end

    # Define a new DataFrame for LaTeX output
    latex_df = DataFrame(
        value = String[],
        ON_volumes = String[],
        Term_volumes = String[]
    )

    latex_code = "\\begin{tabular}{|c||c|c|}\n"
    latex_code *= "\\hline\n"
    latex_code *= "Value $(parameter) & ON volumes & Term volumes \\\\\n"
    latex_code *= "\\hline\n"

    for i in 1:size(results, 1)
        if i > 1 && results[i, :Parameter] == results[i-1, :Parameter]
            latex_code *=  extract_number_before_parentheses(results[i, :ON_volumes]) * " & " * extract_number_before_parentheses(results[i, :Term_volumes]) * " \\\\\n"
            latex_code *= "&" * extract_number_with_parentheses(results[i, :ON_volumes]) * " & " * extract_number_with_parentheses(results[i, :Term_volumes]) * " \\\\\n"
        else
            rowspan = sum(results[i, :Parameter] .== results[i, :Parameter])
            latex_code *= "\\multirow{" * string(rowspan) * "}{*}{" * results[i, :Parameter] * "} & "
            latex_code *= extract_number_before_parentheses(results[i, :ON_volumes]) * " & " * extract_number_before_parentheses(results[i, :Term_volumes]) * " \\\\\n"
            latex_code *= "&" * extract_number_with_parentheses(results[i, :ON_volumes]) * " & " * extract_number_with_parentheses(results[i, :Term_volumes]) * " \\\\\n"
        end
    end
    
    latex_code *= "\\hline\n"
    latex_code *= "\\end{tabular}"
    return latex_code
end

