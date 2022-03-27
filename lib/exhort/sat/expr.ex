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

  @doc """
  Create a new expression using the DSL.

  If the expression contains a comparison operator, it becomes a constraint.
  """
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

  See `Exhort.SAT.Builder.def_interval_var/6`.

  - `name` is the variable name
  - `start` is the start of the interval
  - `size` is the size of the interval
  - `stop` is the end of the interval
  """
  @spec def_interval_var(
          name :: String.t(),
          start :: atom() | String.t(),
          size :: integer(),
          stop :: atom() | String.t(),
          opts :: Keyword.t()
        ) ::
          IntervalVar.t()
  defdelegate def_interval_var(name, start, size, stop, opts \\ []), to: IntervalVar, as: :new

  @doc """
  Definite a constant. It must later be added to the model.
  """
  @spec def_constant(
          name :: String.t() | atom(),
          value :: integer()
        ) :: IntVar.t()
  defdelegate def_constant(name, value), to: IntVar, as: :new

  @doc """
  Add an implication constraint where `bool1` implies `bool2`.
  """
  defmacro implication(bool1, bool2) do
    expr1 = DSL.transform_expression(bool1)
    expr2 = DSL.transform_expression(bool2)

    quote do
      Constraint.implication(unquote(expr1), unquote(expr2))
    end
  end

  @doc """
  Create a constraint on the list ensuring there are no overlap among the
  variables in the list.
  """
  @spec no_overlap(list(), Keyword.t()) :: Constraint.t()
  defdelegate no_overlap(list, opts \\ []), to: Constraint

  @doc """
  Create a constraint on the list ensuring that each variable in the list has a
  different value.
  """
  @spec all_different(list(), Keyword.t()) :: Constraint.t()
  defdelegate all_different(list, opts \\ []), to: Constraint

  @doc """
  Create logical AND constraint on the list of booleans.
  """
  defmacro bool_and(list) when is_list(list) do
    expr_list = Enum.map(list, &DSL.transform_expression(&1))

    quote do
      Constraint.bool_and(unquote(expr_list))
    end
  end

  @doc """
  Create a constraint that requires one of the booleans in the list to be true.
  """
  defmacro bool_or(list) when is_list(list) do
    expr_list = Enum.map(list, &DSL.transform_expression(&1))

    quote do
      Constraint.bool_or(unquote(expr_list))
    end
  end
end
