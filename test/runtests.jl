using Test
using LiveUnicodePlots
using UnicodePlots

@testset "LiveUnicodePlots.jl" begin
    include("test_types.jl")
    include("test_helpers.jl")
    include("test_merging.jl")
    include("test_integration.jl")
end
