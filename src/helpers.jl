# Helper functions for extracting and manipulating keyword arguments in plot expressions

"""
    get_kwargs_from_expr(expr)

Extract keyword arguments from a function call expression.
Returns a vector of keyword argument expressions from the :parameters node.
"""
function get_kwargs_from_expr(expr)
    if !(expr isa Expr) || expr.head != :call
        return Expr[]
    end

    # Check if there's a :parameters node (keyword arguments)
    if length(expr.args) >= 2 && expr.args[2] isa Expr && expr.args[2].head == :parameters
        return expr.args[2].args
    end

    return Expr[]
end

"""
    extract_kwarg_value(expr, key::Symbol, default)

Extract the value of a specific keyword argument from a function call expression.
Returns the value if found, otherwise returns the default.
"""
function extract_kwarg_value(expr, key::Symbol, default)
    kwargs = get_kwargs_from_expr(expr)
    for kwarg in kwargs
        if kwarg isa Expr && kwarg.head == :kw && kwarg.args[1] == key
            return kwarg.args[2]
        end
    end
    return default
end

"""
    extract_width(expr)

Extract the width value from a plot expression.
Returns the width value if present, otherwise returns nothing.
"""
function extract_width(expr)
    kwargs = get_kwargs_from_expr(expr)
    for kwarg in kwargs
        if kwarg isa Expr && kwarg.head == :kw && kwarg.args[1] == :width
            return kwarg.args[2]
        end
    end
    return nothing
end

"""
    extract_height(expr)

Extract the height value from a plot expression.
Returns the height value if present, otherwise returns nothing.
"""
function extract_height(expr)
    kwargs = get_kwargs_from_expr(expr)
    for kwarg in kwargs
        if kwarg isa Expr && kwarg.head == :kw && kwarg.args[1] == :height
            return kwarg.args[2]
        end
    end
    return nothing
end

"""
    extract_title(expr)

Extract the title value from a plot expression.
Returns the title value if present, otherwise returns nothing.
"""
function extract_title(expr)
    kwargs = get_kwargs_from_expr(expr)
    for kwarg in kwargs
        if kwarg isa Expr && kwarg.head == :kw && kwarg.args[1] == :title
            return kwarg.args[2]
        end
    end
    return nothing
end

"""
    remove_title(expr)

Remove the title parameter from a plot expression.
This is used when creating temporary plots for overhead calculation.
"""
function remove_title(expr)
    if !(expr isa Expr) || expr.head != :call
        return expr
    end

    new_args = copy(expr.args)

    # Check if there's a :parameters node
    if length(new_args) >= 2 && new_args[2] isa Expr && new_args[2].head == :parameters
        # Filter out title parameter
        new_kwargs = filter(new_args[2].args) do kwarg
            !(kwarg isa Expr && kwarg.head == :kw && kwarg.args[1] == :title)
        end

        if isempty(new_kwargs)
            # Remove the parameters node entirely if no kwargs left
            deleteat!(new_args, 2)
        else
            new_args[2] = Expr(:parameters, new_kwargs...)
        end
    end

    return Expr(:call, new_args...)
end

"""
    add_width_param(expr, width_var)

Add a width parameter to a plot expression (only if not already present).
"""
function add_width_param(expr, width_var)
    if !(expr isa Expr) || expr.head != :call
        return expr
    end

    # Check if width is already present
    if !isnothing(extract_width(expr))
        return expr
    end

    # Add width parameter
    new_args = copy(expr.args)

    # Check if there's a :parameters node
    if length(new_args) >= 2 && new_args[2] isa Expr && new_args[2].head == :parameters
        # Add to existing parameters node
        new_params = copy(new_args[2].args)
        push!(new_params, Expr(:kw, :width, width_var))
        new_args[2] = Expr(:parameters, new_params...)
    else
        # Create new parameters node
        insert!(new_args, 2, Expr(:parameters, Expr(:kw, :width, width_var)))
    end

    return Expr(:call, new_args...)
end

"""
    replace_auto_width(expr, width_var)

Replace width = :auto with a variable name in a plot expression.
"""
function replace_auto_width(expr, width_var)
    if !(expr isa Expr) || expr.head != :call
        return expr
    end

    new_args = copy(expr.args)

    # Find and modify the parameters node
    if length(new_args) >= 2 && new_args[2] isa Expr && new_args[2].head == :parameters
        new_kwargs = []
        for kwarg in new_args[2].args
            if kwarg isa Expr && kwarg.head == :kw && kwarg.args[1] == :width
                # Check if it's :auto (which is represented as QuoteNode(:auto) or just :auto)
                if kwarg.args[2] == QuoteNode(:auto) || kwarg.args[2] == :(:auto)
                    # Replace with width_var
                    push!(new_kwargs, Expr(:kw, :width, width_var))
                else
                    # Keep as is
                    push!(new_kwargs, kwarg)
                end
            else
                push!(new_kwargs, kwarg)
            end
        end
        new_args[2] = Expr(:parameters, new_kwargs...)
    end

    return Expr(:call, new_args...)
end

"""
    add_height_param(expr, height_var)

Add a height parameter to a plot expression (only if not already present).
"""
function add_height_param(expr, height_var)
    if !(expr isa Expr) || expr.head != :call
        return expr
    end

    # Check if height is already present
    if !isnothing(extract_height(expr))
        return expr
    end

    # Add height parameter
    new_args = copy(expr.args)

    # Check if there's a :parameters node
    if length(new_args) >= 2 && new_args[2] isa Expr && new_args[2].head == :parameters
        # Add to existing parameters node
        new_params = copy(new_args[2].args)
        push!(new_params, Expr(:kw, :height, height_var))
        new_args[2] = Expr(:parameters, new_params...)
    else
        # Create new parameters node
        insert!(new_args, 2, Expr(:parameters, Expr(:kw, :height, height_var)))
    end

    return Expr(:call, new_args...)
end

"""
    replace_auto_height(expr, height_var)

Replace height = :auto with a variable name in a plot expression.
"""
function replace_auto_height(expr, height_var)
    if !(expr isa Expr) || expr.head != :call
        return expr
    end

    new_args = copy(expr.args)

    # Find and modify the parameters node
    if length(new_args) >= 2 && new_args[2] isa Expr && new_args[2].head == :parameters
        new_kwargs = []
        for kwarg in new_args[2].args
            if kwarg isa Expr && kwarg.head == :kw && kwarg.args[1] == :height
                # Check if it's :auto
                if kwarg.args[2] == QuoteNode(:auto) || kwarg.args[2] == :(:auto)
                    # Replace with height_var
                    push!(new_kwargs, Expr(:kw, :height, height_var))
                else
                    # Keep as is
                    push!(new_kwargs, kwarg)
                end
            else
                push!(new_kwargs, kwarg)
            end
        end
        new_args[2] = Expr(:parameters, new_kwargs...)
    end

    return Expr(:call, new_args...)
end
