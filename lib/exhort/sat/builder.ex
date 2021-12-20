defmodule Exhort.SAT.Builder do
  @moduledoc """
  Provide for the building of a model for eventual solving.

  All functions except `build/0` are pure Elixir.

  `build/0` interacts with the underlying native implementation, returning a
  `%Model{}`.
  """

  @type t :: %__MODULE__{}
  defstruct res: nil, vars: %{}, constraints: []

  alias __MODULE__
  alias Exhort.NIF.Nif
  alias Exhort.SAT.BoolVar
  alias Exhort.SAT.Builder
  alias Exhort.SAT.Constraint
  alias Exhort.SAT.IntVar
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
  @spec def_bool_var(Builder.t(), atom() | String.t()) :: Builder.t()
  def def_bool_var(%Builder{vars: vars} = builder, var) do
    %Builder{builder | vars: Map.put(vars, var, %BoolVar{name: var})}
  end

  @doc """
  Define an integer variable in the model.

  - `var` is the variable name
  - `domain` is the uppper and lower bounds of the integer as a tuple,
    `{lower_bound, upper_bound}`
  """
  @spec def_int_var(Builder.t(), atom() | String.t(), {integer(), integer()}) ::
          Builder.t()
  def def_int_var(%Builder{vars: vars} = builder, var, domain) do
    %Builder{builder | vars: Map.put(vars, var, %IntVar{name: var, domain: domain})}
  end

  @doc """
  Define a constraint on the model using variables.

  - `constraint` is specified as an atom. See `Exhort.SAT.Constraint.constraint()`.
  - `var1` and `var2` may be an atom, a string, or an existing `BoolVar` or `IntVar`.
  - `opts` may specify a restriction on the constraint:
      - `if: bool` specifies that a constraint only takes effect if `bool` is true
      - `unless: bool` specifies that a constraint only takes effect if `bool` is false
  """
  @spec constrain(
          Builder.t(),
          Constraint.constraint(),
          atom() | String.t() | BoolVar.t() | IntVar.t(),
          atom() | String.t() | BoolVar.t() | IntVar.t(),
          Keyword.t()
        ) :: Builder.t()
  def constrain(builder, constraint, var1, var2, opts \\ [])

  def constrain(%Builder{} = builder, constraint, %BoolVar{} = var1, %BoolVar{} = var2, opts) do
    cond do
      opts == [] ->
        %Builder{
          builder
          | constraints: builder.constraints ++ [{constraint, var1.name, var2.name}]
        }

      var3 = Keyword.get(opts, :if) ->
        %Builder{
          builder
          | constraints:
              builder.constraints ++ [{constraint, var1.name, var2.name, :if, var3.name}]
        }

      var3 = Keyword.get(opts, :unless) ->
        %Builder{
          builder
          | constraints:
              builder.constraints ++ [{constraint, var1.name, var2.name, :unless, var3.name}]
        }
    end
  end

  def constrain(%Builder{} = builder, constraint, %IntVar{} = var1, %IntVar{} = var2, opts) do
    cond do
      opts == [] ->
        %Builder{
          builder
          | constraints: builder.constraints ++ [{constraint, var1, var2}]
        }

      var3 = Keyword.get(opts, :if) ->
        %Builder{
          builder
          | constraints: builder.constraints ++ [{constraint, var1, var2, :if, var3}]
        }

      var3 = Keyword.get(opts, :unless) ->
        %Builder{
          builder
          | constraints: builder.constraints ++ [{constraint, var1, var2, :unless, var3}]
        }
    end
  end

  def constrain(%Builder{} = builder, constraint, atom1, atom2, opts) do
    cond do
      opts == [] ->
        %Builder{
          builder
          | constraints: builder.constraints ++ [{constraint, atom1, atom2}]
        }

      atom3 = Keyword.get(opts, :if) ->
        %Builder{
          builder
          | constraints: builder.constraints ++ [{constraint, atom1, atom2, :if, atom3}]
        }

      atom3 = Keyword.get(opts, :unless) ->
        %Builder{
          builder
          | constraints: builder.constraints ++ [{constraint, atom1, atom2, :unless, atom3}]
        }
    end
  end

  @spec constrain(Builder.t(), Constraint.constraint(), list()) :: Builder.t()
  def constrain(%Builder{} = builder, constraint, list) do
    %Builder{builder | constraints: builder.constraints ++ [{constraint, list}]}
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
      |> Enum.map(fn
        {name, %BoolVar{} = var} ->
          %BoolVar{res: res} = new_bool_var(builder, to_str(name))
          {name, %BoolVar{var | res: res}}

        {name, %IntVar{domain: {upper_bound, lower_bound}} = var} ->
          %IntVar{res: res} = new_int_var(builder, upper_bound, lower_bound, to_str(name))
          {name, %IntVar{var | res: res}}
      end)
      |> Enum.into(%{})

    builder = %Builder{builder | vars: vars}

    constraints =
      builder.constraints
      |> Enum.map(fn
        {:==, atom1, %LinearExpression{} = expr2} ->
          var1 = Map.get(vars, atom1)
          expr2 = LinearExpression.resolve(expr2, vars)
          add_equal(builder, var1, expr2)

        {:==, %LinearExpression{} = expr, int3, :if, atom4} ->
          expr = LinearExpression.resolve(expr, vars)
          constraint = add_equal(builder, expr, int3)
          only_enforce_if(constraint, Map.get(vars, atom4))
          constraint

        {:==, atom1, int2, :if, atom3} when is_integer(int2) ->
          constraint = add_equal(builder, Map.get(vars, atom1), int2)
          only_enforce_if(constraint, Map.get(vars, atom3))
          constraint

        {:==, atom1, int2, :unless, atom3} when is_integer(int2) ->
          constraint = add_equal(builder, Map.get(vars, atom1), int2)
          only_enforce_if(constraint, bool_not(Map.get(vars, atom3)))
          constraint

        {:==, atom1, int2} when is_integer(int2) ->
          add_equal(builder, Map.get(vars, atom1), int2)

        {:==, atom1, atom2, :if, atom3} ->
          constraint = add_equal(builder, Map.get(vars, atom1), Map.get(vars, atom2))
          only_enforce_if(constraint, Map.get(vars, atom3))
          constraint

        {:==, atom1, atom2, :unless, atom3} ->
          constraint = add_equal(builder, Map.get(vars, atom1), Map.get(vars, atom2))
          only_enforce_if(constraint, bool_not(Map.get(vars, atom3)))
          constraint

        {:==, atom1, atom2} ->
          add_equal(builder, Map.get(vars, atom1), Map.get(vars, atom2))

        {:!=, atom1, atom2} ->
          add_not_equal(builder, Map.get(vars, atom1), Map.get(vars, atom2))

        {:!=, atom1, atom2, :if, atom3} ->
          constraint = add_equal(builder, Map.get(vars, atom1), Map.get(vars, atom2))
          only_enforce_if(constraint, Map.get(vars, atom3))
          constraint

        {:!=, atom1, atom2, :unless, atom3} ->
          constraint = add_equal(builder, Map.get(vars, atom1), Map.get(vars, atom2))
          only_enforce_if(constraint, bool_not(Map.get(vars, atom3)))
          constraint

        {:>=, atom1, int2, :if, atom3} ->
          constraint = add_greater_or_equal(builder, Map.get(vars, atom1), int2)
          only_enforce_if(constraint, Map.get(vars, atom3))
          constraint

        {:<, atom1, int2, :unless, atom3} ->
          constraint = add_less(builder, Map.get(vars, atom1), int2)
          only_enforce_if(constraint, bool_not(Map.get(vars, atom3)))
          constraint

        {:<=, atom1, int2, :unless, atom3} ->
          constraint = add_less_or_equal(builder, Map.get(vars, atom1), int2)
          only_enforce_if(constraint, bool_not(Map.get(vars, atom3)))
          constraint

        {:"abs==", int1, sym2} when is_integer(int1) ->
          add_abs_equal(builder, int1, Map.get(vars, sym2))

        {:"abs==", atom1, atom2} ->
          add_abs_equal(builder, Map.get(vars, atom1), Map.get(vars, atom2))

        {:"all!=", list} ->
          list
          |> Enum.map(fn var ->
            Map.get(vars, var)
            |> then(& &1.res)
          end)
          |> then(fn var_list ->
            add_all_different(builder, var_list)
          end)
      end)

    %Model{res: builder.res, vars: vars, constraints: constraints}
  end

  defp to_str(val) when is_atom(val), do: Atom.to_string(val)
  defp to_str(val), do: val

  defp new_bool_var(%{res: res} = _cp_model_builder, name) do
    res = Nif.new_bool_var_nif(res, name)
    %BoolVar{res: res, name: String.to_atom(name)}
  end

  defp new_int_var(%{res: res} = _cp_model_builder, upper_bound, lower_bound, name) do
    res = Nif.new_int_var_nif(res, upper_bound, lower_bound, name)
    %IntVar{res: res, name: String.to_atom(name), domain: {upper_bound, lower_bound}}
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

  defp add_greater_or_equal(cp_model_builder, %IntVar{} = var1, int2) do
    Nif.add_greater_or_equal_nif(cp_model_builder.res, var1.res, int2)
  end

  defp add_less(cp_model_builder, %IntVar{} = var1, int2) do
    Nif.add_less_nif(cp_model_builder.res, var1.res, int2)
  end

  defp add_less_or_equal(cp_model_builder, %IntVar{} = var1, int2) do
    Nif.add_greater_or_equal_nif(cp_model_builder.res, var1.res, int2)
  end

  defp add_abs_equal(cp_model_builder, %IntVar{} = var1, %IntVar{} = var2) do
    Nif.add_abs_equal_nif(cp_model_builder.res, var1.res, var2.res)
  end

  defp add_abs_equal(cp_model_builder, int1, %IntVar{} = var2) when is_integer(int1) do
    Nif.add_abs_equal_constant_nif(cp_model_builder.res, int1, var2.res)
  end

  defp add_all_different(cp_model_builder, var_list) do
    Nif.add_all_different_nif(cp_model_builder.res, var_list)
  end

  defp only_enforce_if(constraint, %BoolVar{} = var) do
    Nif.only_enforce_if_nif(constraint, var.res)
  end

  defp bool_not(%BoolVar{} = var) do
    %BoolVar{var | res: Nif.bool_not_nif(var.res)}
  end
end
