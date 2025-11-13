# Macros for creating plot layouts

"""
    @layout [plot_expr1, plot_expr2, ...]
    @layout live_plot [plot_expr1, plot_expr2, ...]
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

When used with a LivePlot instance, the width calculation is cached after the first
iteration for better performance in loops.

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

# With caching for loops
live_plot = LivePlot()
for i in 1:100
    live_plot(@layout live_plot [
        lineplot(x_vals, y_vals; title="Data", width=:auto)
    ])
end
```
"""
macro layout(args...)
    if length(args) == 1
        # No LivePlot provided: @layout [plots]
        plots_expr = args[1]
        live_plot_expr = nothing
    elseif length(args) == 2
        # LivePlot provided: @layout live_plot [plots]
        live_plot_expr = args[1]
        plots_expr = args[2]
    else
        error("@layout expects either @layout [plots] or @layout live_plot [plots]")
    end

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
        return esc(_generate_grid_layout_code(plots_expr.args, live_plot_expr))
    else
        # Single row layout
        plot_exprs = plots_expr.args
        num_plots = length(plot_exprs)
        return esc(_generate_layout_code(plot_exprs, num_plots, live_plot_expr))
    end
end

"""
    @live_layout live_plot [plot_expr1, plot_expr2, ...]
    @live_layout live_plot [[plot1, plot2], [plot3, plot4]]  # Grid layout

Convenience macro that combines `@layout` with `LivePlot` rendering in one call.
Equivalent to `live_plot(@layout live_plot [...])` but cleaner and less redundant.

The width calculation is cached in the LivePlot instance after the first iteration
for better performance in loops.

Supports both horizontal layouts (single vector) and grid layouts (vector of vectors).

# Examples
```julia
live_plot = LivePlot()

# Horizontal layout
for i in 1:100
    @live_layout live_plot [
        lineplot(x_vals, y_vals; title="Data", width=:auto),
        lineplot(x_vals, y2_vals; title="More Data", width=:auto)
    ]
    sleep(0.05)
end

# Grid layout
for i in 1:100
    @live_layout live_plot [
        [lineplot(x_vals, y_vals; title="sin", width=:auto, height=10),
         lineplot(x_vals, y2_vals; title="cos", width=:auto, height=10)],
        [lineplot(x_vals, y3_vals; title="tan", width=:auto, height=:auto)]
    ]
    sleep(0.05)
end
```
"""
macro live_layout(live_plot_expr, plots_expr)
    if plots_expr.head != :vect
        error("@live_layout expects a vector of plot expressions: @live_layout live_plot [plot1, plot2, ...]")
    end

    # Check if this is a grid layout (Vector of Vectors) or single row
    is_grid = false
    if length(plots_expr.args) > 0
        first_elem = plots_expr.args[1]
        if first_elem isa Expr && first_elem.head == :vect
            is_grid = true
        end
    end

    # Generate the layout code with caching enabled
    layout_code = if is_grid
        _generate_grid_layout_code(plots_expr.args, live_plot_expr)
    else
        plot_exprs = plots_expr.args
        num_plots = length(plot_exprs)
        _generate_layout_code(plot_exprs, num_plots, live_plot_expr)
    end

    # Wrap it in a call to the LivePlot instance
    return esc(quote
        let result = $layout_code
            $(live_plot_expr)(result)
        end
    end)
end
