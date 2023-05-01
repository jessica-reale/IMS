module IMS

using Agents
using StatsBase
using Random

include("model/structs.jl")
include("model/params.jl")
include("model/init.jl")


greet() = print("Hello World!")


function reset_vars!(model)
    model.IBon = 0.0
    model.IBterm = 0.0
    return model
end

end # module IMS
