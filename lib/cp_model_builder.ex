defmodule CpModelBuilder do
  defstruct res: nil, vars: %{}, constraints: []

  def new_builder do
    %CpModelBuilder{}
  end

  def def_bool_var(%CpModelBuilder{vars: vars} = builder, var) do
    %CpModelBuilder{builder | vars: Map.put(vars, var, %BoolVar{name: var})}
  end

  def def_int_var(%CpModelBuilder{vars: vars} = builder, var, domain) do
    %CpModelBuilder{builder | vars: Map.put(vars, var, %IntVar{name: var, domain: domain})}
  end

  def require(builder, constraint, var1, var2, opts \\ [])

  def require(
        %CpModelBuilder{} = builder,
        constraint,
        %BoolVar{} = var1,
        %BoolVar{} = var2,
        opts
      ) do
    cond do
      opts == [] ->
        %CpModelBuilder{
          builder
          | constraints: builder.constraints ++ [{constraint, var1, var2}]
        }

      var3 = Keyword.get(opts, :if) ->
        %CpModelBuilder{
          builder
          | constraints: builder.constraints ++ [{constraint, var1, var2, :if, var3}]
        }

      var3 = Keyword.get(opts, :unless) ->
        %CpModelBuilder{
          builder
          | constraints: builder.constraints ++ [{constraint, var1, var2, :unless, var3}]
        }
    end
  end

  def require(
        %CpModelBuilder{} = builder,
        constraint,
        %IntVar{} = var1,
        %IntVar{} = var2,
        opts
      ) do
    cond do
      opts == [] ->
        %CpModelBuilder{
          builder
          | constraints: builder.constraints ++ [{constraint, var1, var2}]
        }

      var3 = Keyword.get(opts, :if) ->
        %CpModelBuilder{
          builder
          | constraints: builder.constraints ++ [{constraint, var1, var2, :if, var3}]
        }

      var3 = Keyword.get(opts, :unless) ->
        %CpModelBuilder{
          builder
          | constraints: builder.constraints ++ [{constraint, var1, var2, :unless, var3}]
        }
    end
  end

  def require(
        %CpModelBuilder{} = builder,
        constraint,
        atom1,
        atom2,
        opts
      ) do
    cond do
      opts == [] ->
        %CpModelBuilder{
          builder
          | constraints: builder.constraints ++ [{constraint, atom1, atom2}]
        }

      atom3 = Keyword.get(opts, :if) ->
        %CpModelBuilder{
          builder
          | constraints: builder.constraints ++ [{constraint, atom1, atom2, :if, atom3}]
        }

      atom3 = Keyword.get(opts, :unless) ->
        %CpModelBuilder{
          builder
          | constraints: builder.constraints ++ [{constraint, atom1, atom2, :unless, atom3}]
        }
    end
  end

  def build(%CpModelBuilder{} = builder) do
    {:ok, res} = Nif.new_builder_nif()
    builder = %CpModelBuilder{builder | res: res}

    vars =
      builder.vars
      |> Enum.map(fn
        {name, %BoolVar{} = var} ->
          %BoolVar{res: res} = new_bool_var(builder, Atom.to_string(name))
          {name, %BoolVar{var | res: res}}

        {name, %IntVar{domain: {upper_bound, lower_bound}} = var} ->
          %IntVar{res: res} = new_int_var(builder, upper_bound, lower_bound, Atom.to_string(name))
          {name, %IntVar{var | res: res}}
      end)
      |> Enum.into(%{})

    builder = %CpModelBuilder{builder | vars: vars}

    builder.constraints
    |> Enum.map(fn
      {:==, atom1, atom2} ->
        add_equal(builder, Map.get(vars, atom1), Map.get(vars, atom2))

      {:==, %LinearExpression{} = expr, int3, :if, atom4} ->
        expr = LinearExpression.resolve(expr, vars)
        constraint = add_equal(builder, expr, int3)
        only_enforce_if(constraint, Map.get(vars, atom4))

      {:==, atom1, int2, :unless, atom3} when is_integer(int2) ->
        constraint = add_equal(builder, Map.get(vars, atom1), int2)
        only_enforce_if(constraint, bool_not(Map.get(vars, atom3)))
        constraint

      {:==, atom1, atom2, :if, atom3} ->
        constraint = add_equal(builder, Map.get(vars, atom1), Map.get(vars, atom2))
        only_enforce_if(constraint, Map.get(vars, atom3))
        constraint

      {:==, atom1, atom2, :unless, atom3} ->
        constraint = add_equal(builder, Map.get(vars, atom1), Map.get(vars, atom2))
        only_enforce_if(constraint, bool_not(Map.get(vars, atom3)))
        constraint

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
    end)

    builder
  end

  def new do
    {:ok, res} = Nif.new_builder_nif()
    {:ok, %CpModelBuilder{res: res}}
  end

  def new_bool_var(%{res: res} = _cp_model_builder, name) do
    res = Nif.new_bool_var_nif(res, name)
    %BoolVar{res: res, name: String.to_atom(name)}
  end

  def new_int_var(%{res: res} = _cp_model_builder, upper_bound, lower_bound, name) do
    res = Nif.new_int_var_nif(res, upper_bound, lower_bound, name)
    %IntVar{res: res, name: String.to_atom(name), domain: {upper_bound, lower_bound}}
  end

  def add_equal(cp_model_builder, %LinearExpression{} = expr1, constant2) do
    Nif.add_equal_expr_nif(cp_model_builder.res, expr1.res, constant2)
  end

  def add_equal(cp_model_builder, %BoolVar{} = var1, %BoolVar{} = var2) do
    Nif.add_equal_bool_nif(cp_model_builder.res, var1.res, var2.res)
  end

  def add_equal(cp_model_builder, %IntVar{} = var1, %IntVar{} = var2) do
    Nif.add_equal_int_nif(cp_model_builder.res, var1.res, var2.res)
  end

  def add_equal(cp_model_builder, %IntVar{} = var1, int2) do
    Nif.add_equal_int_constant_nif(cp_model_builder.res, var1.res, int2)
  end

  def add_not_equal(cp_model_builder, %BoolVar{} = var1, %BoolVar{} = var2) do
    Nif.add_not_equal_bool_nif(cp_model_builder.res, var1.res, var2.res)
  end

  def add_not_equal(cp_model_builder, %IntVar{} = var1, %IntVar{} = var2) do
    Nif.add_not_equal_int_nif(cp_model_builder.res, var1.res, var2.res)
  end

  def add_greater_or_equal(cp_model_builder, %IntVar{} = var1, int2) do
    Nif.add_greater_or_equal_nif(cp_model_builder.res, var1.res, int2)
  end

  def add_less(cp_model_builder, %IntVar{} = var1, int2) do
    Nif.add_less_nif(cp_model_builder.res, var1.res, int2)
  end

  def add_less_or_equal(cp_model_builder, %IntVar{} = var1, int2) do
    Nif.add_greater_or_equal_nif(cp_model_builder.res, var1.res, int2)
  end

  def only_enforce_if(constraint, %BoolVar{} = var) do
    Nif.only_enforce_if_nif(constraint, var.res)
  end

  def bool_not(%BoolVar{} = var) do
    %BoolVar{var | res: Nif.bool_not_nif(var.res)}
  end

  def solve(%CpModelBuilder{} = cp_model_builder) do
    Nif.solve_nif(cp_model_builder.res)
    |> CpSolverResponse.build(cp_model_builder)
  end
end
