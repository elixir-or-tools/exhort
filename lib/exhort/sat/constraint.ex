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

  alias __MODULE__
  alias Exhort.SAT.BoolVar
  alias Exhort.SAT.DSL
  alias Exhort.SAT.IntVar
  alias Exhort.SAT.LinearExpression

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

  @doc """
  Define a constraint on the model using variables.

  - `constraint` is specified as an atom. See `Exhort.SAT.Constraint`.
  - `lhs` and `rhs` may each either be an atom, string, `LinearExpression`, or
    an existing `BoolVar` or `IntVar`.
  - `opts` may specify a restriction on the constraint:
      - `if: BoolVar` specifies that a constraint only takes effect if `BoolVar`
        is true
      - `unless: BoolVar` specifies that a constraint only takes effect if
        `BoolVar` is false

  - `:==` - `lhs == rhs`
  - `:abs==` - `lhs == abs(rhs)`
  - `:"all!="` - Require each element the provide list has a different value
    from all the rest
  """
  @spec constrain(
          lhs :: atom() | String.t() | BoolVar.t() | IntVar.t() | LinearExpression.t(),
          constraint :: Constraint.constraint(),
          rhs :: atom() | String.t() | BoolVar.t() | IntVar.t() | LinearExpression.t(),
          opts :: [{:if, BoolVar.t()}] | [{:unless, BoolVar.t()}]
        ) :: Constraint.t()
  def constrain(lhs, constraint, rhs, opts \\ []) do
    %Constraint{defn: {lhs, constraint, rhs, opts}}
  end

  @doc """
  Add an implication constraint where `bool1` implies `bool2`.
  """
  def implication(bool1, bool2) do
    %Constraint{defn: {:implication, bool1, bool2}}
  end

  @doc """
  Create a constraint that requires one of the booleans in the list to be true.
  """
  @spec bool_or(list()) :: Exhort.SAT.Constraint.t()
  def bool_or(list) do
    %Constraint{defn: {:or, list}}
  end

  @doc """
  Create longical and constraint on the list of booleans.
  """
  @spec bool_and(list()) :: Exhort.SAT.Constraint.t()
  def bool_and(list) do
    %Constraint{defn: {:and, list}}
  end

  @doc """
  Create a constraint that ensures no overlap among the variables.
  """
  @spec no_overlap(list(), Keyword.t()) :: Exhort.SAT.Constraint.t()
  def no_overlap(list, opts \\ []) do
    %Constraint{defn: {:no_overlap, list, opts}}
  end

  @doc """
  Create a constraint that ensures each item in the list is different in the
  solution.
  """
  @spec all_different(list(), Keyword.t()) :: Exhort.SAT.Constraint.t()
  def all_different(list, opts \\ []) do
    %Constraint{defn: {:"all!=", list, opts}}
  end
end
