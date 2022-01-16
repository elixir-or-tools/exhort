defmodule Exhort.SAT.Expr do
  @moduledoc """
  Create an expression in the expression language.

  If the expression contains a comparison operator, it will be a constraint.
  Otherwise, it will be a linear expression.
  """

  alias Exhort.SAT.DSL
  alias Exhort.SAT.Constraint

  @comparison [:<, :<=, :==, :>=, :>, :"abs=="]

  defmacro new(expr, opts \\ [])

  defmacro new({op, _, [_lhs, _rhs]} = expr, opts) when op in @comparison do
    expr =
      case expr do
        {:==, m1, [lhs, {:abs, _m2, [var]}]} ->
          {:"abs==", m1, [lhs, var]}

        expr ->
          expr
      end

    {op, _, [lhs, rhs]} = expr
    lhs = DSL.transform_expression(lhs)
    rhs = DSL.transform_expression(rhs)
    opts = Enum.map(opts, &DSL.transform_expression(&1))

    quote do
      %Constraint{defn: {unquote(lhs), unquote(op), unquote(rhs), unquote(opts)}}
    end
  end

  defmacro new(expr, _opts) do
    expr = DSL.transform_expression(expr)

    quote do
      unquote(expr)
    end
  end
end
