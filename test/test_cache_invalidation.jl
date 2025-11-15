using Test
using LiveLayoutUnicodePlots
using UnicodePlots

@testset "LivePlot cache signatures" begin
    @testset "LivePlot initialization includes cached_signatures" begin
        lp = LivePlot()
        @test hasfield(LivePlot, :cached_signatures)
        @test lp.cached_signatures isa Vector{Vector{UInt64}}
        @test isempty(lp.cached_signatures)
    end
end

@testset "compute_plot_signature" begin
    @testset "same plot produces same signature" begin
        x = [1, 2, 3, 4, 5]
        y = [1, 4, 9, 16, 25]

        p1 = lineplot(x, y; title="Test")
        p2 = lineplot(x, y; title="Test")

        sig1 = LiveLayoutUnicodePlots.compute_plot_signature(p1)
        sig2 = LiveLayoutUnicodePlots.compute_plot_signature(p2)

        @test sig1 == sig2
        @test sig1 isa UInt64
    end

    @testset "different plot types produce different signatures" begin
        x = [1, 2, 3, 4, 5]
        y = [1, 4, 9, 16, 25]

        p1 = lineplot(x, y)
        p2 = textplot("Hello"; width=10)

        sig1 = LiveLayoutUnicodePlots.compute_plot_signature(p1)
        sig2 = LiveLayoutUnicodePlots.compute_plot_signature(p2)

        @test sig1 != sig2
    end

    @testset "title changes affect signature" begin
        x = [1, 2, 3, 4, 5]
        y = [1, 4, 9, 16, 25]

        p1 = lineplot(x, y; title="Title 1")
        p2 = lineplot(x, y; title="Title 2")
        p3 = lineplot(x, y; title="")

        sig1 = LiveLayoutUnicodePlots.compute_plot_signature(p1)
        sig2 = LiveLayoutUnicodePlots.compute_plot_signature(p2)
        sig3 = LiveLayoutUnicodePlots.compute_plot_signature(p3)

        @test sig1 != sig2
        @test sig1 != sig3
        @test sig2 != sig3
    end

    @testset "label changes affect signature" begin
        x = [1, 2, 3, 4, 5]
        y = [1, 4, 9, 16, 25]

        p1 = lineplot(x, y; xlabel="X")
        p2 = lineplot(x, y; xlabel="X", ylabel="Y")
        p3 = lineplot(x, y)

        sig1 = LiveLayoutUnicodePlots.compute_plot_signature(p1)
        sig2 = LiveLayoutUnicodePlots.compute_plot_signature(p2)
        sig3 = LiveLayoutUnicodePlots.compute_plot_signature(p3)

        @test sig1 != sig2
        @test sig1 != sig3
        @test sig2 != sig3
    end

    @testset "limit changes affect signature" begin
        x = [1, 2, 3, 4, 5]
        y = [1, 4, 9, 16, 25]

        p1 = lineplot(x, y; xlim=(0, 10))
        p2 = lineplot(x, y; xlim=(0, 100))
        p3 = lineplot(x, y)

        sig1 = LiveLayoutUnicodePlots.compute_plot_signature(p1)
        sig2 = LiveLayoutUnicodePlots.compute_plot_signature(p2)
        sig3 = LiveLayoutUnicodePlots.compute_plot_signature(p3)

        @test sig1 != sig2
        @test sig1 != sig3
    end
end
