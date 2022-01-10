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

  The expression must include a boundary: `<`, `<=`, `==`, `>=`, `>`.

  ```
  x < y
  ```

  The components of the expressoin may be simple mathematical expressions,
  including the use of `+` and `*`:

  ```
  x * y = z
  ```

  The `sum/1` function may be used to sum over a series of terms:

  ```
  sum(x + y) == z
  ```

  The variables in the expression are defined in the model and do not by default
  reference the variables in Elixir scope. The pin operator, `^` may be used to
  reference a scoped Elixir variable.

  For example, where `x` is a model variable (e.g., `def_int_var(x, {0, 3}`))
  and `y` is an Elixir variable (e.g., `y = 2`):

  ```
  x < ^y
  ```

  A `for` comprehension may be used to generate list values:

  ```
  sum(for {x, y} <- ^list, do: x * y) == z
  ```

  As a larger example:

  ```
  y = 20
  z = [{0, 1}, {2, 3}, {4, 5}]

  Builder.new()
  |> Builder.def_int_var(x, {0, 3})
  |> Builder.constrain(sum(for {a, b} <- ^z, do: ^a * ^b) < y)
  |> Builder.build()
  ...
  ```
  """

  alias Exhort.SAT.DSL
  alias __MODULE__

  @type constraint :: :< | :<= | :== | :>= | :> | :"abs==" | :"all!=" | :no_overlap

  @type t :: %__MODULE__{}
  defstruct [:res, :defn]

  @doc """
  Define a bounded constraint.
  """
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
