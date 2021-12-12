defmodule CpModelBuilder do
  @on_load :load_nifs

  defstruct [:res]

  def load_nifs do
    :erlang.load_nif('priv/lib/cp_model_builder', 0)
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
    %CpSolverResponse{res: res}
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
