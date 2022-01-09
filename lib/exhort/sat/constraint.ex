defmodule Exhort.SAT.Constraint do
  @moduledoc """
  A constraint on the model.

  The binary constraints are:

  ```
  :< | :<= | :== | :>= | :> | :"abs=="
  ```

  The list constraints are:

  ```
  :"all!=" | :no_overlap
  ```
  """

  alias Exhort.SAT.DSL
  alias __MODULE__

  @type constraint :: :< | :<= | :== | :>= | :> | :"abs==" | :"all!=" | :no_overlap

  @type t :: %__MODULE__{}
  defstruct [:res, :defn]

  defmacro new(expr, opts \\ []) do
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
end
