function on_loans(df::DataFrame, param::Symbol)
    fig = Figure(resolution = (800, 400))
    ax = fig[1,1] = Axis(fig, title = "ON Loans", xlabel = "Steps", ylabel = "Average Volumes")
    gdf = groupby(df, param)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.ON_assets), 14400)
        lines!(trend; 
            label = "$(param) = $(key[1])")
    end
    ax.xticks = 0:200:1200

    fig[1, end+1] = Legend(fig, ax; 
        orientation = :vertical, tellwidth = true)

    return fig
end

function term_loans(df::DataFrame, param::Symbol)
    fig = Figure(resolution = (800, 400))
    ax = fig[1,1] = Axis(fig, title = "Term Loans", xlabel = "Steps", ylabel = "Average Volumes")
    gdf = groupby(df, param)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.Term_assets), 14400)
        lines!(trend; 
            label = "$(param) = $(key[1])")
        end
    ax.xticks = 0:200:1200

    fig[1, end+1] = Legend(fig, ax; 
        orientation = :vertical, tellwidth = true)

    return fig
end

function credit_loans(df::DataFrame, param::Symbol; f::Bool = true)
    fig = Figure(resolution = (800, 400))
    ax = fig[1,1] = Axis(fig, xlabel = "Steps", ylabel = "Average Volumes")
    gdf = groupby(df, param)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.loans), 14400)
        lines!(trend; 
            label = "$(param) = $(key[1])")
    end
    ax.xticks = 0:200:1200

    ax.title = if f 
        "Firms Loans"
        else
            "Households Loans"
        end

    fig[1, end+1] = Legend(fig, ax; 
        orientation = :vertical, tellwidth = true)

    return fig
end

function output(df::DataFrame, param::Symbol)
    fig = Figure(resolution = (800, 400))
    ax = fig[1,1] = Axis(fig, title = "GDP", xlabel = "Steps", ylabel = "Average Volumes")
    gdf = groupby(df, param)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.output), 14400)
        lines!(trend; 
            label = "$(param) = $(key[1])")
    end
    ax.xticks = 0:200:1200

    fig[1, end+1] = Legend(fig, ax; 
        orientation = :vertical, tellwidth = true)

    return fig
end