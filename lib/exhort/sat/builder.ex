defmodule Exhort.SAT.Builder do
  @moduledoc """
  Provide for the building of a model for eventual solving.

  All functions except `build/0` are pure Elixir.

  `build/0` interacts with the underlying native implementation, returning a
  `%Model{}`.
  """

  @type t :: %__MODULE__{}
  defstruct res: nil, vars: [], constraints: [], objectives: []

  alias __MODULE__
  alias Exhort.NIF.Nif
  alias Exhort.SAT.BoolVar
  alias Exhort.SAT.Builder
  alias Exhort.SAT.Constraint
  alias Exhort.SAT.IntVar
  alias Exhort.SAT.IntervalVar
  alias Exhort.SAT.LinearExpression
  alias Exhort.SAT.Model

  @doc """
  Start a new builder.
  """
  @spec new() :: Builder.t()
  def new do
    %Builder{}
  end

  @doc """
  Define a boolean variable in the model.
  """
  @spec def_bool_var(Builder.t(), name :: atom() | String.t()) :: Builder.t()
  def def_bool_var(%Builder{vars: vars} = builder, var) do
    %Builder{builder | vars: vars ++ [%BoolVar{name: var}]}
  end

  @doc """
  Define an integer variable in the model.

  - `var` is the variable name
  - `domain` is the uppper and lower bounds of the integer as a tuple,
    `{lower_bound, upper_bound}`
  """
  @spec def_int_var(Builder.t(), name :: atom() | String.t(), domain :: {integer(), integer()}) ::
          Builder.t()
  def def_int_var(%Builder{vars: vars} = builder, var, domain) do
    %Builder{builder | vars: vars ++ [%IntVar{name: var, domain: domain}]}
  end

  @doc """
  Define an integer variable in the model.

  - `var` is the variable name
  - `domain` is the uppper and lower bounds of the integer as a tuple,
    `{lower_bound, upper_bound}`
  """
  @spec def_interval_var(
          Builder.t(),
          name :: atom() | String.t(),
          start :: atom() | String.t(),
          size :: atom() | String.t(),
          stop :: atom() | String.t()
        ) ::
          Builder.t()
  def def_interval_var(%Builder{vars: vars} = builder, var, start, size, stop) do
    %Builder{
      builder
      | vars: vars ++ [%IntervalVar{name: var, start: start, size: size, stop: stop}]
    }
  end

  @doc """
  Define a constraint on the model using variables.

  - `constraint` is specified as an atom. See
    `Exhort.SAT.Constraint.constraint()`.
  - `lhs` and `rhs` may each either be an atom, string, `LinearExpression`,
    or an existing `BoolVar` or `IntVar`.
  - `opts` may specify a restriction on the constraint:
      - `if: BoolVar` specifies that a constraint only takes effect if `BoolVar` is
        true
      - `unless: BoolVar` specifies that a constraint only takes effect if `BoolVar`
        is false

  - `:==` - `var1 == var2`
  - `:abs==` - `var1 == abs(var2)`
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
  def constrain(builder, lhs, constraint, rhs, opts \\ [])

  def constrain(%Builder{} = builder, lhs, constraint, rhs, opts) do
    cond do
      opts == [] ->
        %Builder{
          builder
          | constraints: builder.constraints ++ [{lhs, constraint, rhs}]
        }

      literal = Keyword.get(opts, :if) ->
        %Builder{
          builder
          | constraints: builder.constraints ++ [{lhs, constraint, rhs, :if, literal}]
        }

      literal = Keyword.get(opts, :unless) ->
        %Builder{
          builder
          | constraints: builder.constraints ++ [{lhs, constraint, rhs, :unless, literal}]
        }
    end
  end

  @spec constrain(Builder.t(), Constraint.constraint(), list()) :: Builder.t()
  def constrain(%Builder{} = builder, constraint, list) do
    %Builder{builder | constraints: builder.constraints ++ [{constraint, list}]}
  end

  @spec max_equality(Builder.t(), sym :: atom() | String.t() | IntVar.t(), list()) :: Builder.t()
  def max_equality(builder, sym, list) do
    %Builder{builder | objectives: builder.objectives ++ [{:max_equality, sym, list}]}
  end

  @spec minimize(Builder.t(), sym :: atom() | String.t() | IntVar.t()) :: Builder.t()
  def minimize(builder, sym) do
    %Builder{builder | objectives: builder.objectives ++ [{:minimize, sym}]}
  end

  @doc """
  Build the model. Once the model is built it may be solved.

  This function interacts with the underlying native model.
  """
  @spec build(Builder.t()) :: Model.t()
  def build(%Builder{} = builder) do
    builder = %Builder{builder | res: Nif.new_builder_nif()}

    vars =
      builder.vars
      |> Enum.reduce(%{}, fn
        %BoolVar{name: name} = var, vars ->
          %BoolVar{res: res} = new_bool_var(builder, name)
          Map.put(vars, name, %BoolVar{var | res: res})

        %IntVar{name: name, domain: {upper_bound, lower_bound}} = var, vars ->
          %IntVar{res: res} = new_int_var(builder, upper_bound, lower_bound, name)
          Map.put(vars, name, %IntVar{var | res: res})

        %IntervalVar{name: name, start: start, size: size, stop: stop} = var, vars ->
          start =
            Map.get(vars, start)
            |> LinearExpression.resolve(vars)

          size = LinearExpression.resolve(size, vars)

          stop =
            Map.get(vars, stop)
            |> LinearExpression.resolve(vars)

          %IntervalVar{res: res} = new_interval_var(builder, name, start, size, stop)

          Map.put(vars, var.name, %IntervalVar{
            var
            | res: res,
              start: start,
              size: size,
              stop: stop
          })
      end)

    builder = %Builder{builder | vars: vars}

    constraints =
      builder.constraints
      |> Enum.map(fn
        {lhs, :==, %LinearExpression{} = rhs} ->
          rhs = LinearExpression.resolve(rhs, vars)
          add_equal(builder, Map.get(vars, lhs), rhs)

        {%LinearExpression{} = lhs, :==, rhs, :if, literal} ->
          lhs = LinearExpression.resolve(lhs, vars)
          constraint = add_equal(builder, lhs, rhs)
          only_enforce_if(constraint, Map.get(vars, literal))
          constraint

        {lhs, :==, rhs, :if, literal} when is_integer(rhs) ->
          constraint = add_equal(builder, Map.get(vars, lhs), rhs)
          only_enforce_if(constraint, Map.get(vars, literal))
          constraint

        {lhs, :==, rhs, :unless, literal} when is_integer(rhs) ->
          constraint = add_equal(builder, Map.get(vars, lhs), rhs)
          only_enforce_if(constraint, bool_not(Map.get(vars, literal)))
          constraint

        {lhs, :==, rhs} when is_integer(rhs) ->
          add_equal(builder, Map.get(vars, lhs), rhs)

        {lhs, :==, rhs, :if, literal} ->
          constraint = add_equal(builder, Map.get(vars, lhs), Map.get(vars, rhs))
          only_enforce_if(constraint, Map.get(vars, literal))
          constraint

        {lhs, :==, rhs, :unless, literal} ->
          constraint = add_equal(builder, Map.get(vars, lhs), Map.get(vars, rhs))
          only_enforce_if(constraint, bool_not(Map.get(vars, literal)))
          constraint

        {lhs, :==, rhs} ->
          add_equal(builder, Map.get(vars, lhs), Map.get(vars, rhs))

        {lhs, :!=, rhs} ->
          add_not_equal(builder, Map.get(vars, lhs), Map.get(vars, rhs))

        {lhs, :!=, rhs, :if, literal} ->
          constraint = add_equal(builder, Map.get(vars, lhs), Map.get(vars, rhs))
          only_enforce_if(constraint, Map.get(vars, literal))
          constraint

        {lhs, :!=, rhs, :unless, literal} ->
          constraint = add_equal(builder, Map.get(vars, lhs), Map.get(vars, rhs))
          only_enforce_if(constraint, bool_not(Map.get(vars, literal)))
          constraint

        {lhs, :>=, rhs, :if, literal} ->
          constraint = add_greater_or_equal(builder, Map.get(vars, lhs), rhs)
          only_enforce_if(constraint, Map.get(vars, literal))

        {lhs, :>=, rhs} when is_integer(rhs) ->
          constraint = add_greater_or_equal(builder, Map.get(vars, lhs), rhs)
          constraint

        {lhs, :>=, rhs} ->
          constraint = add_greater_or_equal(builder, Map.get(vars, lhs), Map.get(vars, rhs))
          constraint

        {lhs, :<, rhs, :unless, literal} ->
          constraint = add_less(builder, Map.get(vars, lhs), rhs)
          only_enforce_if(constraint, bool_not(Map.get(vars, literal)))
          constraint

        {lhs, :<=, rhs, :unless, literal} ->
          constraint = add_less_or_equal(builder, Map.get(vars, lhs), rhs)
          only_enforce_if(constraint, bool_not(Map.get(vars, literal)))
          constraint

        {lhs, :<=, rhs} ->
          constraint = add_less_or_equal(builder, Map.get(vars, lhs), Map.get(vars, rhs))
          constraint

        {lhs, :"abs==", rhs} when is_integer(lhs) ->
          add_abs_equal(builder, lhs, Map.get(vars, rhs))

        {lhs, :"abs==", rhs} ->
          add_abs_equal(builder, Map.get(vars, lhs), Map.get(vars, rhs))

        {:"all!=", list} ->
          add_all_different(builder, list)

        {:no_overlap, list} ->
          add_no_overlap(builder, list)
      end)

    builder = %Builder{builder | constraints: constraints}

    builder.objectives
    |> Enum.map(fn
      {:max_equality, name, list} ->
        add_max_equality(builder, Map.get(vars, name), list)

      {:minimize, var1} ->
        add_minimize(builder, Map.get(vars, var1))
    end)

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

  defp new_interval_var(%{res: res} = _cp_model_builder, name, start, size, stop) do
    res = Nif.new_interval_var_nif(res, to_str(name), start.res, size.res, stop.res)
    %IntervalVar{res: res, name: name, start: start, size: size, stop: stop}
  end

  defp add_equal(cp_model_builder, %LinearExpression{} = expr1, constant2) do
    Nif.add_equal_expr_nif(cp_model_builder.res, expr1.res, constant2)
  end

  defp add_equal(cp_model_builder, %BoolVar{} = var1, %BoolVar{} = var2) do
    Nif.add_equal_bool_nif(cp_model_builder.res, var1.res, var2.res)
  end

  defp add_equal(cp_model_builder, %IntVar{} = var1, %IntVar{} = var2) do
    Nif.add_equal_int_nif(cp_model_builder.res, var1.res, var2.res)
  end

  defp add_equal(cp_model_builder, %IntVar{} = var1, %LinearExpression{} = expr2) do
    Nif.add_equal_int_expr_nif(cp_model_builder.res, var1.res, expr2.res)
  end

  defp add_equal(cp_model_builder, %IntVar{} = var1, int2) when is_integer(int2) do
    Nif.add_equal_int_constant_nif(cp_model_builder.res, var1.res, int2)
  end

  defp add_not_equal(cp_model_builder, %BoolVar{} = var1, %BoolVar{} = var2) do
    Nif.add_not_equal_bool_nif(cp_model_builder.res, var1.res, var2.res)
  end

  defp add_not_equal(cp_model_builder, %IntVar{} = var1, %IntVar{} = var2) do
    Nif.add_not_equal_int_nif(cp_model_builder.res, var1.res, var2.res)
  end

  defp add_greater_or_equal(cp_model_builder, %IntVar{} = var1, int2) when is_integer(int2) do
    Nif.add_greater_or_equal_constant_nif(cp_model_builder.res, var1.res, int2)
  end

  defp add_greater_or_equal(cp_model_builder, %IntVar{} = var1, %IntVar{} = var2) do
    Nif.add_greater_or_equal_nif(cp_model_builder.res, var1.res, var2.res)
  end

  defp add_less(cp_model_builder, %IntVar{} = var1, int2) do
    Nif.add_less_nif(cp_model_builder.res, var1.res, int2)
  end

  defp add_less_or_equal(cp_model_builder, %IntVar{} = var1, %IntVar{} = var2) do
    Nif.add_less_or_equal_nif(cp_model_builder.res, var1.res, var2.res)
  end

  defp add_less_or_equal(cp_model_builder, %IntVar{} = var1, int2) when is_integer(int2) do
    Nif.add_less_or_equal_constant_nif(cp_model_builder.res, var1.res, int2)
  end

  defp add_abs_equal(cp_model_builder, %IntVar{} = var1, %IntVar{} = var2) do
    Nif.add_abs_equal_nif(cp_model_builder.res, var1.res, var2.res)
  end

  defp add_abs_equal(cp_model_builder, int1, %IntVar{} = var2) when is_integer(int1) do
    Nif.add_abs_equal_constant_nif(cp_model_builder.res, int1, var2.res)
  end

  defp add_all_different(%Builder{res: builder_res, vars: vars} = _builder, list) do
    list
    |> Enum.map(fn var ->
      Map.get(vars, var)
      |> then(& &1.res)
    end)
    |> then(fn var_list ->
      Nif.add_all_different_nif(builder_res, var_list)
    end)
  end

  defp add_no_overlap(%Builder{res: builder_res, vars: vars} = _builder, list) do
    list
    |> Enum.map(fn var ->
      vars
      |> Map.get(var)
      |> then(& &1.res)
    end)
    |> then(fn var_list ->
      Nif.add_no_overlap_nif(builder_res, var_list)
    end)
  end

  defp only_enforce_if(constraint, %BoolVar{} = var) do
    Nif.only_enforce_if_nif(constraint, var.res)
  end

  defp bool_not(%BoolVar{} = var) do
    %BoolVar{var | res: Nif.bool_not_nif(var.res)}
  end

  defp add_max_equality(%Builder{res: builder_res, vars: vars}, %IntVar{} = var1, list) do
    list
    |> Enum.map(fn var ->
      Map.get(vars, var)
      |> then(& &1.res)
    end)
    |> then(fn var_list ->
      Nif.add_max_equality_nif(builder_res, var1.res, var_list)
    end)
  end

  defp add_minimize(%Builder{res: builder_res}, %IntVar{} = var1) do
    Nif.add_minimize_nif(builder_res, var1.res)
  end
end
