# base theme settings
fontsize_theme = Theme(fontsize = 16, font = "DroidSerif-Regular.ttf")
set_theme!(fontsize_theme)

# define constants to be used in plots generation
const SHIFT = 100
const BY_STATUS = ("deficit", "surplus")
const SHOCKS = ("Missing", "Corridor", "Width", "Uncertainty")

# helper functions
function add_lines!(gdf)
    lines!(gdf.icbt[SHIFT:end]; linestyle = :dot, color = :black, linewidth = 3)
    lines!(gdf.icbd[SHIFT:end];  linestyle = :dot, color = :black, linewidth = 3)
    lines!(gdf.icbl[SHIFT:end];  linestyle = :dot, color = :black, linewidth = 3)
end

function invisible_yaxis!(fig, i)
    if i > 1
        fig.content[i].yticklabelsvisible = false
        fig.content[i].yticksvisible = false
    end
end

function plots_levels_vars(fig, axes, gdf, vars, titles)
    for i in 1:length(vars)
        xaxis, yaxis = i == 1 && length(vars) > 4 ? (1:2, 1) : axes[i]
        ax = fig[xaxis..., yaxis] = Axis(fig, title = titles[i])
        for j in 1:length(gdf)
            _, trend = hp_filter(gdf[j][!, vars[i]][SHIFT:end], 129600)
            lines!(trend; label = only(unique(gdf[j].shock)), linewidth = 3)
            fig.content[1].ylabel =  L"\text{Mean}"
            fig.content[i].xlabel = L"\text{Steps}"
        end
        ax.xticks = SHIFT:300:1200            
    end
end

function plots_levels_shock(fig, axes, gdf, vars, labels) 
    for i in 1:length(gdf)
        ax = fig[axes[i]...] = Axis(fig, title = SHOCKS[i])
        for j in 1:length(vars)
        _, trend = hp_filter(gdf[i][!, vars[j]][SHIFT:end], 129600)
            lines!(trend; label = labels[j], linewidth = 3)
            fig.content[1].ylabel =  L"\text{Mean}"
            fig.content[i].xlabel = L"\text{Steps}"
            add_lines!(gdf[i])
        end
        ax.xticks = SHIFT:300:1200
    end
end

function plots_group(fig, axes, gdf, vars)
    for i in eachindex(BY_STATUS)
        ax = fig[axes[i]...] = Axis(fig, title =  BY_STATUS[i])
        for j in 1:length(gdf)
            sdf = filter(r -> r.status == BY_STATUS[i], gdf[j])
            _, trend = hp_filter(sdf[!, vars[1]][SHIFT:end], 129600)
            lines!(trend; label = only(unique(gdf[j].shock)), linewidth = 3)
            fig.content[1].ylabel =  L"\text{Mean}"
            fig.content[i].xlabel = L"\text{Steps}"
        end
        invisible_yaxis!(fig, i)
        ax.xticks = SHIFT:300:1200 
    end
    linkyaxes!(fig.content...)
end

function plots_rationing(fig, axes, gdf, vars, vars_den, titles)
    for i in 1:length(vars)
        ax = fig[axes[i]...] = Axis(fig, title = titles[i])
        for j in 1:length(gdf)
            _, trend = hp_filter((1 .- gdf[j][!, vars[i]][SHIFT:end] ./ gdf[j][!, vars_den[i]][SHIFT:end]) .* 100, 129600)
            lines!(trend; label = only(unique(gdf[j].shock)), linewidth = 3)
            fig.content[1].ylabel =  L"\text{Rate (%)}"
            fig.content[i].xlabel = L"\text{Steps}"
        end
        invisible_yaxis!(fig, i)
        ax.xticks = SHIFT:300:1200
    end
    linkyaxes!(fig.content...)
end

function plots_area(fig, axes, df, vars)
    df = filter(:status => x -> x != "neutral", df)
    gdf = groupby(df, :status)

    for i in eachindex(SHOCKS)
        ax = fig[axes[i]...] = Axis(fig, title = SHOCKS[i], ytickformat = "{:.1f}")
        for j in 1:length(gdf)
            sdf = filter(r -> r.shock == SHOCKS[i], gdf[j])
            _, trend = hp_filter(sdf[!, vars[1]][SHIFT:end], 129600)
            band!(sdf.step[SHIFT:end] .- 100, min.(trend) .+ mean.(trend) .+ std(trend), 
                max.(trend) .- mean.(trend) .- std(trend); label = BY_STATUS[j],
                color = j == 1 ? Makie.wong_colors()[end] : Makie.wong_colors()[1])
            fig.content[1].ylabel =  L"\text{Mean}"
            fig.content[i].xlabel = L"\text{Steps}"
        end
        invisible_yaxis!(fig, i)
        ax.xticks = SHIFT:300:1200
    end
    linkyaxes!(fig.content...)
end

# generate plots
function generate_plots(df::DataFrame, 
    vars::Vector{Symbol}, 
    vars_den::Union{Missing, Vector{Symbol}},
    titles::Union{Missing, Vector{LaTeXStrings.LaTeXString}}, 
    labels::Union{Missing, Vector{LaTeXStrings.LaTeXString}}; 
    rationing::Bool = false, 
    area::Bool = false, 
    status::Bool = false, 
    by_vars::Bool = false)

    fig = Figure(resolution = (1200, 400))

    # group df by shock
    gdf = groupby(df, :shock)
    # define custom length of axes according to type of plot
    custom_length() = (by_vars || rationing) ? length(vars) : (status ? length(BY_STATUS) : length(gdf))
    # define axes positions
    axes = tuple(collect((1, i) for i in 1:custom_length())...)

    if rationing
        plots_rationing(fig, axes, gdf, vars, vars_den, titles)
    elseif status
        plots_group(fig, axes, gdf, vars)
    elseif area
        plots_area(fig, axes, df, vars) # groupby within plots_area function
    elseif by_vars
        plots_levels_vars(fig, axes, gdf, vars, titles)
    else
        plots_levels_shock(fig, axes, gdf, vars, labels)
    end

    fig[end+1, 1:custom_length()] = Legend(fig, 
        fig.content[1];
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal, 
        )

    return fig
end
