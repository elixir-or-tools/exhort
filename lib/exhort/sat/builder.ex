defmodule Exhort.SAT.Builder do
  @moduledoc """
  Provide for the building of a model for eventual solving.

  All functions except `build/0` are pure Elixir.

  Create a new builder with `new/0`. Build a model with `build/0`.

  `build/0` interacts with the underlying native implementation, returning a
  `Exhort.SAT.Model` struct.
  """

  alias __MODULE__
  alias Exhort.NIF.Nif
  alias Exhort.SAT.BoolVar
  alias Exhort.SAT.Builder
  alias Exhort.SAT.Constraint
  alias Exhort.SAT.DSL
  alias Exhort.SAT.IntervalVar
  alias Exhort.SAT.IntVar
  alias Exhort.SAT.LinearExpression
  alias Exhort.SAT.Model
  alias Exhort.SAT.Vars

  require __MODULE__

  defmacro __using__(_options) do
    quote do
      alias Exhort.SAT.BoolVar
      alias Exhort.SAT.Builder
      alias Exhort.SAT.Constraint
      alias Exhort.SAT.Expr
      alias Exhort.SAT.IntervalVar
      alias Exhort.SAT.IntVar
      alias Exhort.SAT.LinearExpression
      alias Exhort.SAT.Model
      alias Exhort.SAT.SolverResponse

      require Exhort.SAT.Builder
      require Exhort.SAT.Constraint
      require Exhort.SAT.Expr
      require Exhort.SAT.LinearExpression
      require Exhort.SAT.SolverResponse
    end
  end

  @type t :: %__MODULE__{}
  defstruct res: nil, vars: %Vars{}, constraints: [], objectives: [], decision_strategy: nil

  @doc """
  Start a new builder.
  """
  @spec new() :: Builder.t()
  def new do
    %Builder{}
  end

  @doc """
  Add an item or list of items to the builder.
  """
  @spec add(Builder.t(), list() | BoolVar.t() | IntVar.t() | Constraint.t()) :: Builder.t()
  def add(builder, list) when is_list(list) do
    Enum.reduce(list, builder, &add(&2, &1))
  end

  def add(%Builder{vars: vars} = builder, %BoolVar{} = var) do
    %Builder{builder | vars: Vars.add(vars, var)}
  end

  def add(%Builder{vars: vars} = builder, %IntVar{} = var) do
    %Builder{builder | vars: Vars.add(vars, var)}
  end

  def add(%Builder{vars: vars} = builder, %IntervalVar{} = var) do
    %Builder{builder | vars: Vars.add(vars, var)}
  end

  def add(%Builder{constraints: constraints} = builder, %Constraint{} = constraint) do
    %Builder{builder | constraints: constraints ++ [constraint]}
  end

  @doc """
  Define a boolean variable in the model.
  """
  def def_bool_var(%Builder{vars: vars} = builder, name) do
    %Builder{builder | vars: Vars.add(vars, %BoolVar{name: name})}
  end

  @doc """
  Define an integer variable in the model.

  - `name` is the variable name
  - `domain` is the uppper and lower bounds of the integer as a tuple,
    `{lower_bound, upper_bound}`
  """
  def def_int_var(%Builder{vars: vars} = builder, name, domain) do
    %Builder{builder | vars: Vars.add(vars, %IntVar{name: name, domain: domain})}
  end

  @doc """
  Define an interval variable in the model.

  See
  https://developers.google.com/optimization/reference/python/sat/python/cp_model#intervalvar

  - `name` is the variable name
  - `start` is the start of the interval
  - `size` is the size of the interval
  - `stop` is the end of the interval
  - `opts` may specify `if: bool_var`, where `bool_var` being a previously
    defined boolean variable
  """
  def def_interval_var(%Builder{vars: vars} = builder, name, start, size, stop, opts \\ []) do
    %Builder{
      builder
      | vars:
          Vars.add(vars, %IntervalVar{
            name: name,
            start: start,
            size: size,
            stop: stop,
            opts: opts
          })
    }
  end

  @doc """
  Create a named constant. `value` should be a constant integer.
  """
  def def_constant(%Builder{vars: vars} = builder, name, value) do
    %Builder{builder | vars: Vars.add(vars, %IntVar{name: name, domain: value})}
  end

  @doc """
  See `Exhort.SAT.Constraint`.

  Define a bounded constraint.

  The expression must include a boundary like `==`, `<=`, `>`, etc.

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
  defmacro constrain(builder, expr, opts \\ []) do
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
      %Builder{} = builder = unquote(builder)

      %Builder{
        builder
        | constraints:
            builder.constraints ++
              [%Constraint{defn: {unquote(lhs), unquote(op), unquote(rhs), unquote(opts)}}]
      }
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
          builder :: Builder.t(),
          lhs :: atom() | String.t() | BoolVar.t() | IntVar.t() | LinearExpression.t(),
          constraint :: Constraint.constraint(),
          rhs :: atom() | String.t() | BoolVar.t() | IntVar.t() | LinearExpression.t(),
          opts :: [{:if, BoolVar.t()}] | [{:unless, BoolVar.t()}]
        ) :: Builder.t()
  def constrain(%Builder{} = builder, lhs, constraint, rhs, opts \\ []) do
    %Builder{
      builder
      | constraints: builder.constraints ++ [%Constraint{defn: {lhs, constraint, rhs, opts}}]
    }
  end

  @doc """
  Apply the constraint to the given list.

  See `Exhort.SAT.Constraint` for the list of constraints.
  """
  @spec constrain_list(Builder.t(), Constraint.constraint(), list(), opts :: Keyword.t()) ::
          Builder.t()
  def constrain_list(%Builder{} = builder, constraint, list, opts \\ []) do
    %Builder{
      builder
      | constraints: builder.constraints ++ [%Constraint{defn: {constraint, list, opts}}]
    }
  end

  @doc """
  Add a constraint on the variable named by `literal` to the list of items in `list`.
  """
  @spec max_equality(Builder.t(), literal :: atom() | String.t() | IntVar.t(), list()) ::
          Builder.t()
  def max_equality(builder, literal, list) do
    %Builder{builder | objectives: builder.objectives ++ [{:max_equality, literal, list}]}
  end

  @doc """
  Specify an objective to minimize `literal`.
  """
  defmacro minimize(builder, expression) do
    expression = DSL.transform_expression(expression)

    quote do
      %Builder{vars: vars} = builder = unquote(builder)
      %Builder{builder | objectives: builder.objectives ++ [{:minimize, unquote(expression)}]}
    end
  end

  @doc """
  Specify an objective to maximize `expression`.
  """
  defmacro maximize(builder, expression) do
    expression = DSL.transform_expression(expression)

    quote do
      %Builder{vars: vars} = builder = unquote(builder)
      %Builder{builder | objectives: builder.objectives ++ [{:maximize, unquote(expression)}]}
    end
  end

  @doc """
  Specifiy a decision strategy on a list of variables.
  """
  @spec decision_strategy(
          Builder.t(),
          list(),
          variable_selection_strategy ::
            :choose_first
            | :choose_lowest_min
            | :choose_highest_max
            | :choose_min_domain_size
            | :choose_max_domain_size,
          domain_reduction_strategy ::
            :select_min_value
            | :select_max_value
            | :select_lower_half
            | :select_upper_half
            | :select_median_value
        ) :: Builder.t()
  def decision_strategy(
        builder,
        vars,
        variable_selection_strategy,
        domain_reduction_strategy
      ) do
    %Builder{
      builder
      | decision_strategy: {vars, variable_selection_strategy, domain_reduction_strategy}
    }
  end

  @doc """
  Provide reduction that accepts the builder as the first argument and the
  enumerable as the second, faciliating pipelines with the `Builder`.
  """
  @spec reduce(Builder.t(), Enumerable.t(), function()) :: Builder.t()
  def reduce(builder, items, f) do
    Enum.reduce(items, builder, f)
  end

  @doc """
  Build the model. Once the model is built it may be solved.

  This function interacts with the underlying native model.
  """
  @spec build(Builder.t()) :: Model.t()
  def build(%Builder{} = builder) do
    builder = %Builder{builder | res: Nif.new_builder_nif()}

    vars =
      Vars.iter(builder.vars)
      |> Enum.reduce(%Vars{}, fn
        %BoolVar{name: name} = var, vars ->
          %BoolVar{res: res} = new_bool_var(builder, name)
          Vars.add(vars, %BoolVar{var | res: res})

        %IntVar{name: name, domain: {upper_bound, lower_bound}} = var, vars ->
          %IntVar{res: res} = new_int_var(builder, upper_bound, lower_bound, name)
          Vars.add(vars, %IntVar{var | res: res})

        %IntVar{name: name, domain: constant} = var, vars ->
          %IntVar{res: res} = new_constant(builder, name, constant)
          Vars.add(vars, %IntVar{var | res: res})

        %IntervalVar{
          name: name,
          start: start,
          size: size,
          stop: stop,
          opts: [if: presence]
        } = var,
        vars ->
          start =
            Vars.get(vars, start)
            |> LinearExpression.resolve(vars)

          size = LinearExpression.resolve(size, vars)

          stop =
            Vars.get(vars, stop)
            |> LinearExpression.resolve(vars)

          presence = BoolVar.resolve(presence, vars)

          %IntervalVar{res: res} =
            new_interval_var(builder, name, start, size, stop, if: presence)

          Vars.add(vars, %IntervalVar{
            var
            | res: res,
              start: start,
              size: size,
              stop: stop,
              opts: [if: presence]
          })

        %IntervalVar{name: name, start: start, size: size, stop: stop, opts: opts} = var, vars ->
          start =
            Vars.get(vars, start)
            |> LinearExpression.resolve(vars)

          size = LinearExpression.resolve(size, vars)

          stop =
            Vars.get(vars, stop)
            |> LinearExpression.resolve(vars)

          %IntervalVar{res: res} = new_interval_var(builder, name, start, size, stop, opts)

          Vars.add(vars, %IntervalVar{
            var
            | res: res,
              start: start,
              size: size,
              stop: stop,
              opts: opts
          })
      end)

    builder = %Builder{builder | vars: vars}

    constraints =
      builder.constraints
      |> Enum.map(fn
        %Constraint{defn: {lhs, :==, rhs, opts}} = constraint ->
          lhs = LinearExpression.resolve(lhs, vars)
          rhs = LinearExpression.resolve(rhs, vars)
          res = builder |> add_equal(lhs, rhs) |> modify(opts, vars)
          %Constraint{constraint | res: res}

        %Constraint{defn: {lhs, :!=, rhs, opts}} = constraint ->
          lhs = LinearExpression.resolve(lhs, vars)
          rhs = LinearExpression.resolve(rhs, vars)
          res = builder |> add_not_equal(lhs, rhs) |> modify(opts, vars)
          %Constraint{constraint | res: res}

        %Constraint{defn: {lhs, :>, rhs, opts}} = constraint ->
          lhs = LinearExpression.resolve(lhs, vars)
          rhs = LinearExpression.resolve(rhs, vars)
          res = builder |> add_greater_than(lhs, rhs) |> modify(opts, vars)
          %Constraint{constraint | res: res}

        %Constraint{defn: {lhs, :>=, rhs, opts}} = constraint ->
          lhs = LinearExpression.resolve(lhs, vars)
          rhs = LinearExpression.resolve(rhs, vars)
          res = builder |> add_greater_or_equal(lhs, rhs) |> modify(opts, vars)
          %Constraint{constraint | res: res}

        %Constraint{defn: {lhs, :<, rhs, opts}} = constraint ->
          lhs = LinearExpression.resolve(lhs, vars)
          rhs = LinearExpression.resolve(rhs, vars)
          res = builder |> add_less_than(lhs, rhs) |> modify(opts, vars)
          %Constraint{constraint | res: res}

        %Constraint{defn: {lhs, :<=, rhs, opts}} = constraint ->
          lhs = LinearExpression.resolve(lhs, vars)
          rhs = LinearExpression.resolve(rhs, vars)
          res = builder |> add_less_or_equal(lhs, rhs) |> modify(opts, vars)
          %Constraint{constraint | res: res}

        %Constraint{defn: {lhs, :"abs==", rhs, opts}} = constraint when is_integer(lhs) ->
          res = builder |> add_abs_equal(lhs, Vars.get(vars, rhs)) |> modify(opts, vars)
          %Constraint{constraint | res: res}

        %Constraint{defn: {lhs, :"abs==", rhs, opts}} = constraint ->
          res =
            builder
            |> add_abs_equal(Vars.get(vars, lhs), Vars.get(vars, rhs))
            |> modify(opts, vars)

          %Constraint{constraint | res: res}

        %Constraint{defn: {:implication, lhs, rhs}} = constraint ->
          lhs = BoolVar.resolve(lhs, vars)
          rhs = BoolVar.resolve(rhs, vars)
          res = add_implication(builder, lhs, rhs)
          %Constraint{constraint | res: res}

        %Constraint{defn: {:or, list}} = constraint ->
          list = Enum.map(list, &BoolVar.resolve(&1, vars))
          res = add_bool_or(builder, list)
          %Constraint{constraint | res: res}

        %Constraint{defn: {:and, list}} = constraint ->
          list = Enum.map(list, &BoolVar.resolve(&1, vars))
          res = add_bool_and(builder, list)
          %Constraint{constraint | res: res}

        %Constraint{defn: {:"all!=", list, opts}} = constraint ->
          list = Enum.map(list, &LinearExpression.resolve(&1, vars))
          res = builder |> add_all_different(list) |> modify(opts, vars)
          %Constraint{constraint | res: res}

        %Constraint{defn: {:no_overlap, list, opts}} = constraint ->
          res = builder |> add_no_overlap(list) |> modify(opts, vars)
          %Constraint{constraint | res: res}
      end)

    builder = %Builder{builder | constraints: constraints}

    builder.objectives
    |> Enum.map(fn
      {:max_equality, name, list} ->
        add_max_equality(builder, Vars.get(vars, name), list)

      {:minimize, expr1} ->
        expr1 = LinearExpression.resolve(expr1, vars)
        add_minimize(builder, expr1)

      {:maximize, expr1} ->
        expr1 = LinearExpression.resolve(expr1, vars)
        add_maximize(builder, expr1)
    end)

    add_decision_strategy(builder, builder.decision_strategy, vars)

    %Model{res: builder.res, vars: vars, constraints: constraints}
  end

  defp to_str(val) when is_atom(val), do: Atom.to_string(val)
  defp to_str(val), do: val

  defp new_bool_var(%{res: res} = _cp_model_builder, name) do
    res = Nif.new_bool_var_nif(res, to_str(name))
    %BoolVar{res: res, name: name}
  end

  defp new_int_var(%{res: res} = _cp_model_builder, upper_bound, lower_bound, name) do
    res = Nif.new_int_var_nif(res, upper_bound, lower_bound, to_str(name))
    %IntVar{res: res, name: name, domain: {upper_bound, lower_bound}}
  end

  defp new_constant(%{res: res} = _cp_model_builder, name, value) do
    res = Nif.new_constant_nif(res, to_str(name), value)
    %IntVar{res: res, name: name, domain: value}
  end

  defp new_interval_var(%{res: res} = _cp_model_builder, name, start, size, stop, [
         {:if, presence}
       ]) do
    res =
      Nif.new_optional_interval_var_nif(
        res,
        to_str(name),
        start.res,
        size.res,
        stop.res,
        presence.res
      )

    %IntervalVar{
      res: res,
      name: name,
      start: start,
      size: size,
      stop: stop,
      opts: [{:if, presence}]
    }
  end

  defp new_interval_var(%{res: res} = _cp_model_builder, name, start, size, stop, []) do
    res = Nif.new_interval_var_nif(res, to_str(name), start.res, size.res, stop.res)
    %IntervalVar{res: res, name: name, start: start, size: size, stop: stop}
  end

  defp add_equal(cp_model_builder, %LinearExpression{} = expr1, %LinearExpression{} = expr2) do
    Nif.add_equal_expr1_expr2_nif(cp_model_builder.res, expr1.res, expr2.res)
  end

  defp add_not_equal(cp_model_builder, %LinearExpression{} = expr1, %LinearExpression{} = expr2) do
    Nif.add_not_equal_expr1_expr2_nif(cp_model_builder.res, expr1.res, expr2.res)
  end

  defp add_greater_or_equal(
         cp_model_builder,
         %LinearExpression{} = expr1,
         %LinearExpression{} = expr2
       ) do
    Nif.add_greater_or_equal_expr1_expr2_nif(cp_model_builder.res, expr1.res, expr2.res)
  end

  defp add_greater_than(
         cp_model_builder,
         %LinearExpression{} = expr1,
         %LinearExpression{} = expr2
       ) do
    Nif.add_greater_than_expr1_expr2_nif(cp_model_builder.res, expr1.res, expr2.res)
  end

  defp add_less_than(cp_model_builder, %LinearExpression{} = expr1, %LinearExpression{} = expr2) do
    Nif.add_less_than_expr1_expr2_nif(cp_model_builder.res, expr1.res, expr2.res)
  end

  defp add_less_or_equal(
         cp_model_builder,
         %LinearExpression{} = expr1,
         %LinearExpression{} = expr2
       ) do
    Nif.add_less_or_equal_expr1_expr2_nif(cp_model_builder.res, expr1.res, expr2.res)
  end

  defp add_abs_equal(cp_model_builder, %IntVar{} = var1, %IntVar{} = var2) do
    Nif.add_abs_equal_nif(cp_model_builder.res, var1.res, var2.res)
  end

  defp add_abs_equal(cp_model_builder, int1, %IntVar{} = var2) when is_integer(int1) do
    Nif.add_abs_equal_constant_nif(cp_model_builder.res, int1, var2.res)
  end

  defp add_implication(cp_model_builder, %BoolVar{} = var1, %BoolVar{} = var2) do
    Nif.add_implication_nif(cp_model_builder.res, var1.res, var2.res)
  end

  defp add_all_different(%Builder{res: builder_res} = _builder, list) do
    list
    |> Enum.map(& &1.res)
    |> then(fn var_list ->
      Nif.add_all_different_nif(builder_res, var_list)
    end)
  end

  defp add_no_overlap(%Builder{res: builder_res, vars: vars} = _builder, list) do
    list
    |> Enum.map(fn var ->
      vars
      |> Vars.get(var)
      |> then(& &1.res)
    end)
    |> then(fn var_list ->
      Nif.add_no_overlap_nif(builder_res, var_list)
    end)
  end

  defp modify(constraint, opts, vars) do
    Enum.each(opts, fn
      {:if, sym} ->
        only_enforce_if(constraint, Vars.get(vars, sym))

      {:unless, sym} ->
        only_enforce_if(constraint, bool_not(Vars.get(vars, sym)))
    end)

    constraint
  end

  defp only_enforce_if(constraint, %BoolVar{} = var) do
    Nif.only_enforce_if_nif(constraint, var.res)
  end

  defp bool_not(%BoolVar{} = var) do
    %BoolVar{var | res: Nif.bool_not_nif(var.res)}
  end

  defp add_bool_or(%Builder{res: builder_res, vars: _vars} = _builder, list) do
    list
    |> Enum.map(& &1.res)
    |> then(fn var_list ->
      Nif.add_bool_or_nif(builder_res, var_list)
    end)
  end

  defp add_bool_and(%Builder{res: builder_res, vars: vars} = _builder, list) do
    list
    |> Enum.map(fn var ->
      vars
      |> Vars.get(var)
      |> then(& &1.res)
    end)
    |> then(fn var_list ->
      Nif.add_bool_and_nif(builder_res, var_list)
    end)
  end

  defp add_max_equality(%Builder{res: builder_res, vars: vars}, %IntVar{} = var1, list) do
    list
    |> Enum.map(fn var ->
      Vars.get(vars, var)
      |> then(& &1.res)
    end)
    |> then(fn var_list ->
      Nif.add_max_equality_nif(builder_res, var1.res, var_list)
    end)
  end

  defp add_minimize(%Builder{res: builder_res}, %LinearExpression{} = expr1) do
    Nif.add_minimize_nif(builder_res, expr1.res)
  end

  defp add_maximize(%Builder{res: builder_res}, %LinearExpression{} = expr1) do
    Nif.add_maximize_nif(builder_res, expr1.res)
  end

  defp add_decision_strategy(_, nil, _), do: nil

  defp add_decision_strategy(
         builder,
         {list, variable_selection_strategy, domain_reduction_strategy},
         vars
       ) do
    variable_selection_strategies = %{
      choose_first: 0,
      choose_lowest_min: 1,
      choose_highest_max: 2,
      choose_min_domain_size: 3,
      choose_max_domain_size: 4
    }

    domain_reduction_strategies = %{
      select_min_value: 0,
      select_max_value: 1,
      select_lower_half: 2,
      select_upper_half: 3,
      select_median_value: 4
    }

    list
    |> Enum.map(fn var ->
      Vars.get(vars, var)
      |> then(& &1.res)
    end)
    |> then(fn var_list ->
      Nif.add_decision_strategy_nif(
        builder.res,
        var_list,
        Map.fetch!(variable_selection_strategies, variable_selection_strategy),
        Map.fetch!(domain_reduction_strategies, domain_reduction_strategy)
      )
    end)
  end
end
