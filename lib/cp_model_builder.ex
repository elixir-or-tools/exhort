defmodule CpModelBuilder do
  @on_load :load_nifs

  defstruct res: nil, vars: %{}, constraints: []

  def load_nifs do
    :erlang.load_nif('priv/lib/cp_model_builder', 0)
  end

  def new_builder do
    %CpModelBuilder{}
  end

  def def_bool_var(%{vars: vars} = builder, var) do
    %CpModelBuilder{builder | vars: Map.put(vars, var, %BoolVar{name: var})}
  end

  def def_int_var(%{vars: vars} = builder, var, domain) do
    %CpModelBuilder{builder | vars: Map.put(vars, var, %IntVar{name: var, domain: domain})}
  end

  def require(builder, constraint, var1, var2) do
    %CpModelBuilder{builder | constraints: builder.constraints ++ [{constraint, var1, var2}]}
  end

  def require(builder, constraint, var1, var2, if: var) do
    %CpModelBuilder{
      builder
      | constraints: builder.constraints ++ [{constraint, var1, var2, :if, var}]
    }
  end

  def require(builder, constraint, var1, var2, unless: var) do
    %CpModelBuilder{
      builder
      | constraints: builder.constraints ++ [{constraint, var1, var2, :unless, var}]
    }
  end

  def build(builder) do
    {:ok, res} = new_nif()
    builder = %CpModelBuilder{builder | res: res}

    vars =
      builder.vars
      |> Enum.map(fn
        {var, %BoolVar{}} ->
          bool_var = new_bool_var(builder, Atom.to_string(var))
          {var, bool_var}

        {var, %IntVar{domain: {upper_bound, lower_bound}}} ->
          int_var = new_int_var(builder, upper_bound, lower_bound, Atom.to_string(var))
          {var, int_var}
      end)
      |> Enum.into(%{})

    builder.constraints
    |> Enum.map(fn
      {:==, atom1, atom2} ->
        add_equal(builder, Map.get(vars, atom1), Map.get(vars, atom2))

      {:==, %LinearExpression{expr: {:sum, atom1, atom2}} = expr, int3, :if, bool4} ->
        var1 = Map.get(vars, atom1)
        var2 = Map.get(vars, atom2)
        expr_res = sum_nif(var1.res, var2.res)
        expr = %LinearExpression{expr | res: expr_res}
        constraint = add_equal(builder, expr, int3)
        var4 = Map.get(vars, bool4)
        only_enforce_if(constraint, var4)
        constraint

      {:==, atom1, atom2, :if, bool} ->
        constraint = add_equal(builder, Map.get(vars, atom1), Map.get(vars, atom2))
        only_enforce_if(constraint, bool)
        constraint

      {:==, atom1, atom2, :unless, bool3} when is_atom(atom1) and is_atom(atom2) ->
        var1 = Map.get(vars, atom1)
        var2 = Map.get(vars, atom2)
        constraint = add_equal(builder, var1, var2)
        only_enforce_if(constraint, bool_not(Map.get(vars, bool3)))
        constraint

      {:==, atom1, int2, :unless, bool3} when is_atom(atom1) and is_integer(int2) ->
        var1 = Map.get(vars, atom1) |> IO.inspect(label: "### 1", printable_limit: :infinity)
        constraint = add_equal(builder, var1, int2)
        only_enforce_if(constraint, bool_not(Map.get(vars, bool3)))
        constraint

      {:!=, atom1, atom2} ->
        add_not_equal(builder, Map.get(vars, atom1), Map.get(vars, atom2))

      {:!=, atom1, atom2, :if, bool} ->
        constraint = add_equal(builder, Map.get(vars, atom1), Map.get(vars, atom2))
        only_enforce_if(constraint, bool)
        constraint

      {:!=, atom1, atom2, :unless, bool} ->
        constraint = add_equal(builder, Map.get(vars, atom1), Map.get(vars, atom2))
        only_enforce_if(constraint, bool_not(bool))
        constraint

      {:>=, atom1, int2, :if, bool3} ->
        var1 = Map.get(vars, atom1)
        var3 = Map.get(vars, bool3)
        constraint = add_greater_or_equal(builder, var1, int2)
        only_enforce_if(constraint, var3)
        constraint

      {:<=, atom1, int2, :unless, bool3} ->
        var1 = Map.get(vars, atom1)
        var3 = Map.get(vars, bool3)
        constraint = add_less_or_equal(builder, var1, int2)
        only_enforce_if(constraint, bool_not(var3))
        constraint
    end)

    %CpModelBuilder{builder | vars: vars}
  end

  def bool_val(%{builder: %{vars: vars}} = response, atom) do
    %BoolVar{res: var_res} = Map.get(vars, atom)

    if solution_bool_value_nif(response.res, var_res) == 1 do
      true
    else
      false
    end
  end

  def int_val(%{builder: %{vars: vars}} = response, atom) do
    %IntVar{res: var_res} = Map.get(vars, atom)
    solution_integer_value_nif(response.res, var_res)
  end

  def new do
    {:ok, res} = new_nif()
    {:ok, %CpModelBuilder{res: res}}
  end

  def new_bool_var(%{res: res} = _cp_model_builder, name) do
    res = new_bool_var_nif(res, name)
    %BoolVar{res: res, name: String.to_atom(name)}
  end

  def new_int_var(%{res: res} = _cp_model_builder, upper_bound, lower_bound, name) do
    res = new_int_var_nif(res, upper_bound, lower_bound, name)
    %IntVar{res: res, name: String.to_atom(name), domain: {upper_bound, lower_bound}}
  end

  def add_equal(cp_model_builder, %LinearExpression{} = expr1, constant2) do
    add_equal_expr_nif(cp_model_builder.res, expr1.res, constant2)
  end

  def add_equal(cp_model_builder, %BoolVar{} = var1, %BoolVar{} = var2) do
    add_equal_bool_nif(cp_model_builder.res, var1.res, var2.res)
  end

  def add_equal(cp_model_builder, %IntVar{} = var1, %IntVar{} = var2) do
    add_equal_int_nif(cp_model_builder.res, var1.res, var2.res)
  end

  def add_equal(cp_model_builder, %IntVar{} = var1, int2) do
    add_equal_int_constant_nif(cp_model_builder.res, var1.res, int2)
  end

  def add_not_equal(cp_model_builder, %BoolVar{} = var1, %BoolVar{} = var2) do
    add_not_equal_bool_nif(cp_model_builder.res, var1.res, var2.res)
  end

  def add_not_equal(cp_model_builder, %IntVar{} = var1, %IntVar{} = var2) do
    add_not_equal_int_nif(cp_model_builder.res, var1.res, var2.res)
  end

  def add_greater_or_equal(cp_model_builder, %IntVar{} = var1, int2) do
    add_greater_or_equal_nif(cp_model_builder.res, var1.res, int2)
  end

  def add_less_or_equal(cp_model_builder, %IntVar{} = var1, int2) do
    add_greater_or_equal_nif(cp_model_builder.res, var1.res, int2)
  end

  def only_enforce_if(constraint, %BoolVar{} = var) do
    only_enforce_if_nif(constraint, var.res)
  end

  def bool_not(%BoolVar{} = var) do
    %BoolVar{var | res: bool_not_nif(var.res)}
  end

  def solve(cp_model_builder) do
    res = solve_nif(cp_model_builder.res)
    %CpSolverResponse{res: res, builder: cp_model_builder}
  end

  def solution_integer_value(response, var) do
    solution_integer_value_nif(response.res, var.res)
  end

  def new_nif do
    {:ok, :res}
  end

  def new_bool_var_nif(_cp_model_builder, _name) do
  end

  def new_int_var_nif(_cp_model_builder, _upper_bound, _lower_bound, _name) do
  end

  def add_equal_expr_nif(_cp_model_builder, _var1, _var2) do
  end

  def add_equal_bool_nif(_cp_model_builder, _var1, _var2) do
  end

  def add_not_equal_bool_nif(_cp_model_builder, _var1, _var2) do
  end

  def add_equal_int_nif(_cp_model_builder, _var1, _var2) do
  end

  def add_equal_int_constant_nif(_cp_model_builder, _var1, _var2) do
  end

  def add_not_equal_int_nif(_cp_model_builder, _var1, _var2) do
  end

  def add_greater_or_equal_nif(_cp_model_builder, _var1, _var2) do
  end

  def add_less_or_equal_nif(_cp_model_builder, _var1, _var2) do
  end

  def only_enforce_if_nif(_constraint, _var) do
  end

  def bool_not_nif(_var) do
  end

  def solve_nif(_cp_model_builder) do
  end

  def solution_integer_value_nif(_cp_model_builder, _var) do
  end

  def solution_bool_value_nif(_cp_model_builder, _var) do
    true
  end

  def sum_nif(_var1, _var2) do
  end
end
