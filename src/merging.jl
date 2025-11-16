# Functions for merging plots horizontally and vertically

"""
    merge_plots_horizontal(plots::Vector)

Merge multiple plots horizontally by combining their string representations line by line.
Similar to how Plots.jl handles subplot layouts with UnicodePlots backend.

# Arguments
- `plots`: Vector of plot objects to merge
"""
function merge_plots_horizontal(plots::Vector)
    # Convert each plot to string and split into lines
    plot_lines = map(plots) do p
        io = IOBuffer()
        # Create an IOContext with color support enabled
        io_ctx = IOContext(io, :color => true)
        show(io_ctx, MIME("text/plain"), p)
        split(String(take!(io)), '\n')
    end

    # Get the maximum number of lines across all plots
    max_lines = maximum(length.(plot_lines))

    # Helper to strip ANSI codes
    strip_ansi = (s::AbstractString) -> replace(s, r"\e\[[0-9;]*m" => "")

    # Pad all plots to have the same number of lines
    for i in 1:length(plot_lines)
        if length(plot_lines[i]) < max_lines
            # Get the maximum display width across all lines in this plot
            # (strip ANSI codes to get actual display width)
            line_width = maximum(length(strip_ansi(line)) for line in plot_lines[i])
            # Pad with empty lines of the same width
            padding = fill(" " ^ line_width, max_lines - length(plot_lines[i]))
            plot_lines[i] = vcat(plot_lines[i], padding)
        end
    end

    # Merge lines horizontally
    merged_lines = String[]
    for line_idx in 1:max_lines
        line_parts = [plot_lines[i][line_idx] for i in 1:length(plots)]
        push!(merged_lines, join(line_parts, "  "))  # Add 2 spaces between plots
    end

    return join(merged_lines, '\n')
end

"""
    merge_plots_vertical(rows::Vector{String})

Merge plot rows vertically by joining them with newlines.

# Arguments
- `rows`: Vector of strings, where each string is a fully merged row of plots
"""
function merge_plots_vertical(rows::Vector{String})
    return join(rows, '\n')
end
