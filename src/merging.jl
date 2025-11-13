# Functions for merging plots horizontally and vertically

"""
    merge_plots_horizontal(plots::Vector; truncate_to_terminal::Bool=false)

Merge multiple plots horizontally by combining their string representations line by line.
Similar to how Plots.jl handles subplot layouts with UnicodePlots backend.

# Arguments
- `plots`: Vector of plot objects to merge
- `truncate_to_terminal`: If true, truncate lines that exceed terminal width (useful for cached layouts)
"""
function merge_plots_horizontal(plots::Vector; truncate_to_terminal::Bool=false)
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

    # Truncate if requested and necessary
    if truncate_to_terminal
        term_width = displaysize(stdout)[2]
        merged_lines = map(merged_lines) do line
            display_length = length(strip_ansi(line))
            if display_length > term_width
                truncate_line_preserving_ansi(line, term_width)
            else
                line
            end
        end
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

"""
    truncate_line_preserving_ansi(line::String, max_width::Int)

Truncate a line to max_width display characters while preserving ANSI color codes.
"""
function truncate_line_preserving_ansi(line::String, max_width::Int)
    # Parse ANSI codes and text segments
    ansi_pattern = r"\e\[[0-9;]*m"

    result = IOBuffer()
    display_count = 0
    pos = 1

    while pos <= lastindex(line) && display_count < max_width
        # Check for ANSI code at current position
        m = match(ansi_pattern, SubString(line, pos))
        if !isnothing(m) && m.offset == 1
            # Write ANSI code (doesn't count toward display width)
            write(result, m.match)
            pos += length(m.match)
        else
            # Regular character - write it and advance position correctly
            if display_count < max_width
                write(result, line[pos])
                display_count += 1
            end
            pos = nextind(line, pos)
        end
    end

    # Add reset code if we truncated
    if display_count == max_width && pos <= lastindex(line)
        write(result, "\e[0m")
    end

    return String(take!(result))
end
