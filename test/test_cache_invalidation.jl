using Test
using LiveLayoutUnicodePlots

@testset "LivePlot cache signatures" begin
    @testset "LivePlot initialization includes cached_signatures" begin
        lp = LivePlot()
        @test hasfield(LivePlot, :cached_signatures)
        @test lp.cached_signatures isa Vector{Vector{UInt64}}
        @test isempty(lp.cached_signatures)
    end
end
