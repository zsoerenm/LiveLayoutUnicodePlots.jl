# Macros for creating plot layouts

"""
    @layout [plot_expr1, plot_expr2, ...]
    @layout [[plot1, plot2], [plot3, plot4]]  # Grid layout

Macro for rendering multiple UnicodePlots side-by-side or in a grid with automatic
width and height negotiation.

For horizontal layouts, plots with `width = :auto` will have their width automatically
calculated to fit the terminal.

For grid layouts (Vector of Vectors), each inner vector represents a row:
- Width negotiation happens within each row
- Height negotiation happens between rows
- If any plot in a row has fixed height, use the maximum for that row
- If all plots in a row have :auto or no height, divide remaining space equally

# Examples
```julia
# Horizontal layout
@layout [
    lineplot(x, sin.(x); title="sin(x)", width=:auto),
    lineplot(x, cos.(x); title="cos(x)", width=30)
]

# Grid layout (2 rows, 2 plots per row)
@layout [
    [lineplot(x, sin.(x); title="sin", width=:auto, height=10),
     lineplot(x, cos.(x); title="cos", width=:auto, height=10)],
    [lineplot(x, tan.(x); title="tan", width=:auto, height=:auto),
     lineplot(x, -tan.(x); title="-tan", width=:auto, height=:auto)]
]

# With LivePlot for animations
live_plot = LivePlot()
for i in 1:100
    live_plot(@layout [
        lineplot(x_vals, y_vals; title="Data", width=:auto)
    ])
    sleep(0.05)
end
```
"""
macro layout(plots_expr)
    if plots_expr.head != :vect
        error("@layout expects a vector of plot expressions: @layout [plot1, plot2, ...]")
    end

    # Check if this is a grid layout (Vector of Vectors) or single row
    is_grid = false
    if length(plots_expr.args) > 0
        # Check if first element is a vector
        first_elem = plots_expr.args[1]
        if first_elem isa Expr && first_elem.head == :vect
            is_grid = true
        end
    end

    if is_grid
        # Grid layout - Vector of Vectors
        return esc(_generate_grid_layout_code(plots_expr.args))
    else
        # Single row layout
        plot_exprs = plots_expr.args
        num_plots = length(plot_exprs)
        return esc(_generate_layout_code(plot_exprs, num_plots))
    end
end
