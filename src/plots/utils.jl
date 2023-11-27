# base theme settings
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

function extract_number_before_parentheses(str::String)
    m = match(r"^([^\s]+) \(", str)
    return m !== nothing ? m.captures[1] : nothing
end

function extract_number_with_parentheses(str::String)
    m = match(r"(\([^\)]+\))", str)
    return m !== nothing ? m.captures[1] : nothing
end

function add_lines!(gdf)
    # Add dotted lines to the plot for the specified variables in gdf
    lines!(gdf.icbt_mean[SHIFT:end]; color = :grey, linewidth = 0.5)
    lines!(gdf.icbd_mean[SHIFT:end]; color = :grey, linewidth = 0.5)
    lines!(gdf.icbl_mean[SHIFT:end]; color = :grey, linewidth = 0.5)
end

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

function invisible_yaxis!(fig, index)
    # Hide y-axis labels and ticks for subplots starting from the second subplot
    if index > 1
        fig.content[index].yticklabelsvisible = false
        fig.content[index].yticksvisible = false
    end
end

# Set features of axes; currently not used but useful to have plots having (i, j) rows for i in 1:length(vars) and j in 1:length(gdf)
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
        fig.content[start_idx].alignmode = Mixed(left = 0)

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
                fig.content[k].xlabel = "Steps"
            end
        end
    end

    # Set titles only in the first row of plots
    for i in 1:length(gdf)
        fig.content[i].title = only(unique(gdf[i].shock))
    end

end
