include("utils.jl")

# define constants to be used in plots generation
const SHIFT = 100
const BY_STATUS = ("deficit", "surplus")
const SHOCKS = ("Missing", "Corridor", "Width", "Uncertainty")

# generate plots
function generate_plots(df::DataFrame, vars::Vector{Symbol};
    # keywords arguments
    vars_den = Symbol[],
    ylabels = String[], 
    labels = String[],
    rationing = false, 
    area = false, 
    status = false, 
    by_vars = false)

    # Set resolution based on number of row plots 
    resolution = length(vars) > 2 ? (1200, 800) : (1200, 400)

    # Group df by shock
    gdf = groupby(df, :shock)
    
    # Define custom length of axes according to type of plot
    custom_length() = (by_vars || rationing) ? length(vars) : (status ? length(BY_STATUS) : length(gdf))

    # Define figure and allow for super title space above each subfigure with gridsize
    fig = Figure(resolution = resolution)

    # Generate Plots
    if rationing
        plots_vars_shocks(fig, gdf, vars, ylabels; double = (rationing = rationing, vars_den = vars_den))
    elseif status
        plots_group(fig, gdf, vars, ylabels)
    elseif area
        plots_area(fig, df, vars, labels) # groupby within plots_area function
    elseif by_vars
        plots_vars_shocks(fig, gdf, vars, ylabels)
    else
        plots_shock_vars(fig, gdf, vars, labels)
    end

    # Add Legend for labels
    if !isempty(labels)
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
    linestyles = [:solid, :dash]

    # Iterate over each gdf
    for i in 1:length(gdf)
        # Define axes positions
        axes = tuple(collect((1, i) for i in 1:length(gdf))...)
        ax = fig[axes[i]...] = Axis(fig, title = SHOCKS[i])
        
        for j in 1:length(vars)
            # Apply HP filter to the selected variable
            _, trend = hp_filter(gdf[i][!, vars[j]][SHIFT:end], 129600)

            # Plot the main trend line with labels
            lines!(trend; label = labels[j], linewidth = 2, linestyle = linestyles[j])

            # Plot standard deviation bands
            standard_deviation_bands!(gdf[i], trend)

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
                max.(trend) .- mean.(trend) .- std(trend); label = labels[j],
                color = j == 1 ? :black : :grey)
            
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
        for j in 1:length(gdf)
            axes = (i, j)
            ax = fig[axes...] = Axis(fig)
    
            # Apply HP filter to the selected variable
            _, trend = if !double.rationing
                    hp_filter(gdf[j][!, vars[i]][SHIFT:end], 129600)
                else
                    hp_filter((1 .- gdf[j][!, vars[i]][SHIFT:end] ./ gdf[j][!, double.vars_den[i]][SHIFT:end]) .* 100, 129600)
                end

            # Plot the main trend line
            lines!(trend; color = :black, linewidth = 2)

            # Add standard deviation lines
            standard_deviation_bands!(gdf[j], trend)
            
            # Set ticks x-axys
            ax.xticks = SHIFT:300:1200
        end
    end

    # Set axes features
    set_axes!(fig, gdf, vars, ylabels)
end

function plots_group(fig, gdf, vars, ylabels)
    for i in eachindex(BY_STATUS)
        for j in 1:length(gdf)
            xaxis = (i, j)  # Position in the grid
            ax = fig[xaxis...] = Axis(fig)
            
            # Filter the data for the current status
            sdf = filter(r -> r.status_unique == BY_STATUS[i], gdf[j])

            # Apply HP filter to the selected variable
            _, trend = hp_filter(sdf[!, vars[length(vars)]][SHIFT:end], 129600)

            # Plot the main trend line
            lines!(trend; color = :black, linewidth = 2)

            # Add standard deviation lines
            standard_deviation_bands!(sdf, trend)

            # Set ticks x-axys
            ax.xticks = SHIFT:300:1200
        end
    end

    # Set axes features
    set_axes!(fig, gdf, vars, ylabels; status = true)
end
