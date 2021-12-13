defmodule CpModelBuilder do
  @on_load :load_nifs

  defstruct res: nil, ints: %{}, bools: %{}, ineq: []

  def load_nifs do
    :erlang.load_nif('priv/lib/cp_model_builder', 0)
  end

  def new_builder do
    %CpModelBuilder{}
  end

  def new_int_var(%{ints: ints} = builder, var, domain) do
    %CpModelBuilder{builder | ints: Map.put(ints, var, domain)}
  end

  def require(builder, :!=, var1, var2) do
    %CpModelBuilder{builder | ineq: builder.ineq ++ [{var1, var2}]}
  end

  def req_not_eq(builder, var1, var2) do
    %CpModelBuilder{builder | ineq: builder.ineq ++ [{var1, var2}]}
  end

  def build(builder) do
    {:ok, res} = new_nif()
    builder = %CpModelBuilder{builder | res: res}

    int_vars =
      builder.ints
      |> Enum.map(fn {var, {upper_bound, lower_bound}} ->
        int_var = new_int_var(builder, upper_bound, lower_bound, Atom.to_string(var))
        {var, int_var}
      end)
      |> Enum.into(%{})

    builder.ineq
    |> Enum.map(fn {atom1, atom2} ->
      add_not_equal(builder, Map.get(int_vars, atom1), Map.get(int_vars, atom2))
    end)

    %CpModelBuilder{builder | ints: int_vars}
  end

  def int_val(%{builder: %{ints: ints}} = response, atom) do
    var = Map.get(ints, atom)
    solution_integer_value_nif(response.res, var.res)
  end

  def new do
    {:ok, res} = new_nif()
    {:ok, %CpModelBuilder{res: res}}
  end

  def new_int_var(%{res: res} = _cp_model_builder, upper_bound, lower_bound, name) do
    res = new_int_var_nif(res, upper_bound, lower_bound, name)
    %IntVar{res: res}
  end

  def add_not_equal(cp_model_builder, var1, var2) do
    add_not_equal_nif(cp_model_builder.res, var1.res, var2.res)
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

  def new_int_var_nif(_cp_model_builder, _upper_bound, _lower_bound, _name) do
  end

  def add_not_equal_nif(_cp_model_builder, _var1, _var2) do
  end

  def solve_nif(_cp_model_builder) do
  end

  def solution_integer_value_nif(_cp_model_builder, _var) do
  end

  def print(_text) do
  end
end
