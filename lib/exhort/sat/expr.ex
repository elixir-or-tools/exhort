defmodule Exhort.SAT.Expr do
  @moduledoc """
  Create an expression in the expression language.

  If the expression contains a comparison operator, it will be a constraint.
  Otherwise, it will be a linear expression.

  Use the `new/2` macro to create a new expression.

  Use the remaining functions to create variables and list-based constraints.
  """

  alias Exhort.SAT.DSL
  alias Exhort.SAT.BoolVar
  alias Exhort.SAT.Constraint
  alias Exhort.SAT.IntVar
  alias Exhort.SAT.IntervalVar

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

  @doc """
  Define a new integer variable. It must later be added to the model.
  """
  @spec def_int_var(
          name :: String.t(),
          domain :: {lower_bound :: integer(), upper_bound :: integer()} | integer()
        ) ::
          IntVar.t()
  defdelegate def_int_var(name, domain), to: IntVar, as: :new

  @doc """
  Define a new boolean variable. It must later be added to the model.
  """
  @spec def_bool_var(name :: String.t()) :: BoolVar.t()
  defdelegate def_bool_var(name), to: BoolVar, as: :new

  @doc """
  Define an interval variable. It must later be added to the model.

  See `Exhort.SAT.Builder.def_interval_var/3`.

  - `name` is the variable name
  - `start` is the start of the interval
  - `size` is the size of the interval
  - `stop` is the end of the interval
  """
  @spec def_interval_var(
          name :: String.t(),
          start :: atom() | String.t(),
          size :: integer(),
          stop :: atom() | String.t()
        ) ::
          IntervalVar.t()
  defdelegate def_interval_var(name, start, size, stop), to: IntervalVar, as: :new

  @doc """
  Definite a constant. It must later be added to the model.
  """
  @spec def_constant(
          name :: String.t() | atom(),
          value :: integer()
        ) :: IntVar.t()
  defdelegate(def_constant(name, value), to: IntVar, as: :new)

  @doc """
  Create a constraint on the list ensuring there are no overlap among the
  variables in the list.
  """
  @spec no_overlap(list(), Keyword.t()) :: Constraint.t()
  defdelegate no_overlap(list, opts), to: Constraint

  @doc """
  Create a constraint on the list ensuring that each variable in the list has a
  different value.
  """
  @spec all_different(list(), Keyword.t()) :: Constraint.t()
  defdelegate all_different(list, opts), to: Constraint
end
