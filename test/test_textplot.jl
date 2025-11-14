using Test
using LiveLayoutUnicodePlots

@testset "TextPlot Types" begin
    @testset "textplot() creates TextPlot with correct structure" begin
        tp = textplot("Hello World")

        @test tp isa LiveLayoutUnicodePlots.TextPlot
        @test hasfield(typeof(tp), :graphics)
        @test hasfield(typeof(tp.graphics), :char_width)
        @test hasfield(typeof(tp.graphics), :char_height)
    end
end
