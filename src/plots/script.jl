using Pkg
Pkg.activate("src/plots")
Pkg.instantiate()

# Load packages & code libraries
using DataFrames
using CSV
using Pipe
using Statistics
using CairoMakie
using QuantEcon
using Distributions

include("lib.jl")

# define constants to avoid replications
const SCENARIOS = ["Baseline", "Maturity"]
const SAMPLE_SIZES = collect((25:25:100))
const SHOCKS_ = ["Missing", "Corridor", "Width", "Uncertainty"]

const vars_ib = [:lending_facility_mean, :deposit_facility_mean, :loans_mean,
    :am_mean, :bm_mean, :pmb_mean, :pml_mean, :margin_stability_mean, :on_demand_mean, 
    :ON_liabs_mean, :Term_liabs_mean, :term_demand_mean, :il_rate_mean, :id_rate_mean, :flow_mean, 
    :on_supply_mean, :term_supply_mean, :ON_assets_mean, :Term_assets_mean]

# Helper function to save LaTeX tables
function save_to_tex(filename, latex_string)
    open(filename, "w") do f
        write(f, latex_string)
    end
end

# Helper function to generate plots for a specific scenario and sample_size
function generate_scenario_plots(adf::DataFrame, mdf::DataFrame, scenario::String, sample_size::Int)
    df = filter([:scenario, :sample_size] => (x, y) -> x == scenario && y == sample_size, adf)
    df_model = filter([:scenario, :sample_size] => (x, y) -> x == scenario && y == sample_size, mdf)
    overviews_model(df_model)
    overviews_ib(df)
end

# Define functions to generate plots
function overviews_ib(df::DataFrame)
    overviews_ib_big(df)
    overviews_deficit(df)
    overviews_by_status(df)
    overviews_clearing(df)
end

function overviews_model(df::DataFrame)
    p = generate_plots(df, [:ion_mean, :iterm_mean]; 
        labels = ["ON rate", "Term rate"])
    save("ib_rates.eps", p)
end

function overviews_ib_big(df::DataFrame)
    df = @pipe df |> dropmissing(_, vars_ib) |> filter(r -> r.status_unique != "neutral", _) |>
        groupby(_, [:sample_size, :step, :shock, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = generate_plots(df, [:ON_liabs_mean, :Term_liabs_mean, :lending_facility_mean, :deposit_facility_mean]; 
        ylabels = ["Overnight segment", "Term segment", "Lending facility", "Deposit facility"],
        by_vars = true)
    save("big_ib_plots_levels.eps", p)

    p = generate_plots(df, [:am_mean, :bm_mean];
        ylabels = ["ASF", "RSF"], by_vars = true)
    save("stability_ib_plots_levels.eps", p)

    p = generate_plots(df, [:margin_stability_mean];
        ylabels = ["Margin of Stability"], by_vars = true)
    save("margin_stability_levels.eps", p)
end

function overviews_deficit(df)
    df = @pipe df |> dropmissing(_, vars_ib) |> 
        filter([:status_unique, :ib_flag] => (x, y) -> x == "deficit" && y == true, _) |>
        groupby(_, [:sample_size, :step, :shock, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = generate_plots(df, [:ON_liabs_mean, :Term_liabs_mean]; vars_den =  [:on_demand_mean, :term_demand_mean], 
        ylabels = ["Overnight rationing", "Term rationing"], rationing = true)
    save("big_rationing_plot.eps", p)

    p = generate_plots(df, [:on_demand_mean, :term_demand_mean];
        ylabels = ["Overnigth demand", "Term demand"], by_vars = true )
    save("ib_demand_levels.eps", p)
end

function overviews_clearing(df)
    df = @pipe df |> dropmissing(_, vars_ib) |> 
        filter([:status_unique, :ib_flag] => (x, y) -> x != "neutral" && y == true, _) |>
        groupby(_, [:sample_size, :step, :shock, :scenario]) |>
        combine(_, [:clearing_supply, :clearing_demand] .=> mean, renamecols = false)

    p = generate_plots(df, [:clearing_supply, :clearing_demand]; ylabels = ["Supply", "Demand"], by_vars = true)
    save("clearing_ib_market.eps", p)
end

function overviews_by_status(df)
    df = @pipe df |> dropmissing(_, vars_ib) |>
        groupby(_, [:sample_size, :step, :shock, :status_unique, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    p = generate_plots(df, [:margin_stability_mean]; 
        ylabels = ["Deficit", "Surplus"], status = true)
    save("stability_by_status.eps", p)

    p = generate_plots(df, [:loans_mean];  ylabels = ["Deficit", "Surplus"], status = true)
    save("loans_by_status.eps", p)

    p = generate_plots(df, [:flow_mean]; labels = ["Deficit", "Surplus"], area = true)
    save("flows_area.eps", p)
end

function load_data()
    # convert SAMPLE_SIZES constant into String
    sample_sizes = string.(SAMPLE_SIZES)
    # generate empty dataframes
    adf = DataFrame()
    mdf = DataFrame()

    # fill dataframes
    for sample_size in sample_sizes, scenario in SCENARIOS, shock in SHOCKS_
        append!(adf, CSV.File("data/size=$(sample_size)/shock=$(shock)/$(scenario)/adf.csv"); promote = true)
        append!(mdf, CSV.File("data/size=$(sample_size)/shock=$(shock)/$(scenario)/mdf.csv"); promote = true)
    end

    # add vars
    adf[!, :clearing_supply] .= adf.on_supply_mean + adf.term_supply_mean .- (adf.ON_assets_mean .+ adf.Term_assets_mean .+ adf.deposit_facility_mean)
    adf[!, :clearing_demand] .= adf.on_demand_mean + adf.term_demand_mean .- (adf.ON_liabs_mean .+ adf.Term_liabs_mean .+ adf.lending_facility_mean) 

    return adf, mdf
end

# Generate Tables 
function tables(df::DataFrame, scenario::String)
    df = @pipe df |> dropmissing(_, vars_ib) |>  filter(r -> r.ib_flag == true, _) |>
        groupby(_, [:sample_size, :status_unique, :step, :shock, :scenario]) |>
        combine(_, vars_ib .=> mean, renamecols = false)

    latex_table = create_table(df, :ON_liabs_mean, scenario, "Overnight volumes")
    save_to_tex("table_ON_liabs.tex", latex_table)

    latex_table = create_table(df, :Term_liabs_mean, scenario, "Term volumes")
    save_to_tex("table_Term_liabs.tex", latex_table)

    latex_table = create_table(df, :margin_stability_mean, scenario, "Margin of Stability")
    save_to_tex("table_margin_stability.tex", latex_table)
end

# Create LaTeX table for the Appendix - standard deviations
function create_table(df::DataFrame, var::Symbol, scenario::String, var_name::String)
    gdf = @pipe df |> 
        filter([:shock, :scenario, :status_unique] => (x, y, z) -> x == "Missing" && y == scenario && z != "neutral", _) |> 
        groupby(_, :sample_size)

    # Calculate mean, standard deviation, and standard error for each group
    results = DataFrame(sample_size = Int[], mean_var = String[], std_var = Float64[], se_var = Float64[])
    for sdf in gdf
        _, trend = hp_filter(sdf[!, var], 129600)
        mean_val = mean(trend)
        std_val = std(trend)
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

function create_plots_tables(adf, mdf)
    cd(mkpath("img/pdf")) do
        for scenario in SCENARIOS
            cd(mkpath("Main Results")) do
                cd(mkpath("$(scenario)"))
                for sample_size in SAMPLE_SIZES[end] # i.e. 100 sample size
                    generate_scenario_plots(adf, mdf, scenario, sample_size)
                end
            end
            cd(mkpath("Appendix")) do
                cd(mkpath("$(scenario)")) do 
                    tables(adf, "$(scenario)")
                end
            end
        end
    end
    printstyled("Plots and tables generated."; color = :blue)
end

adf, mdf = load_data()
create_plots_tables(adf, mdf)
