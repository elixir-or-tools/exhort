defmodule Exhort.SAT.ExpressionBuilder do
  @moduledoc """
  A CP-SAT model builder that supports simple algerbraic linear equations.

  This means that constraints may be specified as:

  ```
  Builder.constrain(builder, 4 * r + 2 * p == 56)
  ```

  The intent is that expressions are easier to specify and much easier to read.
  """
  alias Exhort.SAT.Builder
  alias Exhort.SAT.DSL
  alias Exhort.SAT.LinearExpression

  @doc """
  See `Exhort.SAT.Builder`
  """
  defdelegate new, to: Builder

  @doc """
  See `Exhort.SAT.Builder`
  """
  defdelegate build(builder), to: Builder

  @doc """
  See `Exhort.SAT.Builder`
  """
  defdelegate maximize(builder, expr), to: Builder

  @doc """
  See `Exhort.SAT.Builder`
  """
  defdelegate reduce(builder, items, f), to: Builder

  @doc """
  See `Exhort.SAT.Builder`
  """
  defmacro def_int_var(builder, var_exp, domain_exp) do
    var = DSL.transform_expression(var_exp)

    quote do
      Builder.def_int_var(unquote(builder), unquote(var), unquote(domain_exp))
    end
  end

  @doc """
  See `Exhort.SAT.Builder`
  """
  defmacro def_constant(builder, var_exp, value) do
    var = DSL.transform_expression(var_exp)

    quote do
      Builder.def_int_var(unquote(builder), unquote(var), unquote(value))
    end
  end

  @doc """
  See `Exhort.SAT.Builder`
  """
  defmacro def_bool_var(builder, var_exp) do
    var = DSL.transform_expression(var_exp)

    quote do
      Builder.def_bool_var(unquote(builder), unquote(var))
    end
  end

  @doc """
  See `Exhort.SAT.Builder`
  """
  defmacro def_interval_var(builder, start_exp, size_expr, stop_expr) do
    start = DSL.transform_expression(start_exp)
    size = DSL.transform_expression(size_expr)
    stop = DSL.transform_expression(stop_expr)

    quote do
      Builder.def_bool_var(unquote(builder), unquote(start), unquote(size), unquote(stop))
    end
  end

  defdelegate constrain(builder, lhs, op, rhs, opts), to: Builder

  @doc """
  Define a constraint on the model.

  ```
  Builder.constrain(builder, 4 * r + 2 * p == 56)
  ```
  """
  defmacro constrain(builder_ast, expr_ast, opts_ast \\ []) do
    transform(builder_ast, expr_ast, opts_ast)
  end

  defp transform(builder, {op, _, [x, y]}, opts_ast) do
    x = DSL.transform_expression(x)
    y = DSL.transform_expression(y)

    opts_ast = Enum.map(opts_ast, &DSL.transform_expression(&1))

    quote do
      Builder.constrain(unquote(builder), unquote(x), unquote(op), unquote(y), unquote(opts_ast))
    end
  end

  defp transform({:*, _, [x, y]}) do
    x = DSL.transform_expression(x)
    y = DSL.transform_expression(y)

    quote do
      LinearExpression.prod(unquote(x), unquote(y))
    end
  end

  defp transform({:+, _, [x, y]}) do
    x = DSL.transform_expression(x)
    y = DSL.transform_expression(y)

    quote do
      LinearExpression.sum(unquote(x), unquote(y))
    end
  end

  defp transform({:sum, _, [args]}) do
    args = DSL.transform_expression(args)

    quote do
      LinearExpression.sum(unquote(args))
    end
  end
end
