# base theme settings
fontsize_theme = Theme(fontsize = 16, font = "DroidSerif-Regular.ttf")
attributes = Attributes(
    Axis = (
        xgridvisible = false,
        ygridvisible = false,
        ytickalign = 1,
        xtickalign = 1,
    ),
)
set_theme!(merge(fontsize_theme, attributes))

# helper functions
function add_lines!(gdf)
    # Add dotted lines to the plot for the specified variables in gdf
    lines!(gdf.icbt_mean[SHIFT:end]; color = :grey, linewidth = 0.5)
    lines!(gdf.icbd_mean[SHIFT:end]; color = :grey, linewidth = 0.5)
    lines!(gdf.icbl_mean[SHIFT:end]; color = :grey, linewidth = 0.5)
end

function standard_deviation_bands!(gdf, trend)
    # Define the lower and upper bounds for the shaded region using std
    lower_bound = trend .- std(trend)
    upper_bound = trend .+ std(trend)
    # Plot the standard deviations as dashed lines
    band!(gdf.step[SHIFT:end] .- SHIFT, upper_bound, lower_bound; color = (:grey, 0.1))
    #lines!(upper_bound; linestyle = :dash, color = :black,  linewidth = 1)
end

function invisible_yaxis!(fig, index)
    # Hide y-axis labels and ticks for subplots starting from the second subplot
    if index > 1
        fig.content[index].yticklabelsvisible = false
        fig.content[index].yticksvisible = false
    end
end

function set_axes!(fig, gdf, vars, ylabels; status::Bool = false)
    index = 0 

    custom_length = status ? length(BY_STATUS) : length(vars)

    for i in 1:custom_length
        index += 1

        # Take the first plots of each row, i.e. (1,1), (2,1), (3,1), (4,1) etc...
        start_idx = (i - 1) * length(gdf) + 1
        # Take the last plots of each row 
        end_idx = start_idx + length(gdf) - 1 

        # Link axes for each variable grouped by shock
        linkyaxes!(fig.content[start_idx:end_idx]...)

        # Write ylabels for each variable only in the first plots of each row
        fig.content[start_idx].ylabel = ylabels[index]

        # Set up the alignment of ylabels
        #fig.content[start_idx].ylabelpadding = 50

        # Apply invisible_yaxis! only on specific plots
        for j in start_idx:end_idx
            mod_val = (j - start_idx + 1) % 4
            if mod_val == 2 || mod_val == 3 || mod_val == 0
                invisible_yaxis!(fig, j)
            end
        end

        # Set the x-label for the last group of subplots
        if i == length(vars)
            for k in (length(fig.content) - length(gdf) + 1):length(fig.content)
                fig.content[k].xlabel = L"\text{Steps}"
            end
        end
    end

    # Set titles only in the first row of plots
    for i in 1:length(gdf)
        fig.content[i].title = only(unique(gdf[i].shock))
    end
end
