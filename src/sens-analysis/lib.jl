function pmb(df::DataFrame, param::Symbol)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Borrowers' preferences for maturities", xlabel = "Steps", ylabel = "Average Volumes")
    gdf = groupby(df, param)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.pmb),  1294400)
        lines!(trend; 
            label = "$(param) = $(key[1])")
    end
    ax.xticks = 0:200:1200

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)
    return fig
end

function pml(df::DataFrame, param::Symbol)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "Lenders' preferences for maturities", xlabel = "Steps", ylabel = "Average Volumes")
    gdf = groupby(df, param)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.pml), 1294400)
        lines!(trend; 
            label = "$(param) = $(key[1])")
        end
    ax.xticks = 0:200:1200

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function credit_loans(df::DataFrame, param::Symbol; f::Bool = true)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, xlabel = "Steps", ylabel = "Average Volumes")
    gdf = groupby(df, param)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.loans), 1294400)
        lines!(trend; 
            label = "$(param) = $(key[1])")
    end
    ax.xticks = 0:200:1200

    ax.title = if f 
        "Firms Loans"
        else
            "Households Loans"
        end

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end

function output(df::DataFrame, param::Symbol)
    fig = Figure(resolution = (600, 300), fontsize = 10)
    ax = fig[1,1] = Axis(fig, title = "GDP", xlabel = "Steps", ylabel = "Average Volumes")
    gdf = groupby(df, param)

    for (key, subdf) in pairs(gdf)
        _, trend = hp_filter((subdf.output), 1294400)
        lines!(trend; 
            label = "$(param) = $(key[1])")
    end
    ax.xticks = 0:200:1200

    fig[end + 1, 1:1] = Legend(fig, ax; 
        tellheight = true, 
        tellwidth = false,
        orientation = :horizontal)

    return fig
end