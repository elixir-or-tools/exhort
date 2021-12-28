defmodule Exhort.NIF.Nif do
  @moduledoc """
  Interface to all the NIF implementations.

  What's the best way to add `@spec`s to these functions?
  """
  @on_load :load_nifs

  require Logger

  def load_nifs do
    :erlang.load_nif('priv/lib/nif', 0)
  end

  def new_builder_nif do
    unimplemented().on_unimplemented()
  end

  def new_bool_var_nif(_cp_model_builder, _name) do
    unimplemented().on_unimplemented()
  end

  def new_int_var_nif(_cp_model_builder, _upper_bound, _lower_bound, _name) do
    unimplemented().on_unimplemented()
  end

  def new_constant_nif(_cp_model_builder, _name, _value) do
    unimplemented().on_unimplemented()
  end

  def new_interval_var_nif(_builder, _name, _start, _size, _stop) do
    unimplemented().on_unimplemented()
  end

  def add_equal_expr1_expr2_nif(_cp_model_builder, _expr1, _expr2) do
    unimplemented().on_unimplemented()
  end

  def add_equal_expr1_constant2_nif(_cp_model_builder, _var1, _int2) do
    unimplemented().on_unimplemented()
  end

  def add_not_equal_expr1_expr2_nif(_cp_model_builder, _expr1, _expr2) do
    unimplemented().on_unimplemented()
  end

  def add_not_equal_bool_nif(_cp_model_builder, _var1, _var2) do
    unimplemented().on_unimplemented()
  end

  def add_equal_int_nif(_cp_model_builder, _var1, _var2) do
    unimplemented().on_unimplemented()
  end

  def add_less_than_expr1_expr2_nif(_cp_model_builder, _expr1, _expr2) do
    unimplemented().on_unimplemented()
  end

  def add_less_or_equal_expr1_expr2_nif(_cp_model_builder, _expr1, _expr2) do
    unimplemented().on_unimplemented()
  end

  def add_greater_or_equal_expr1_expr2_nif(_cp_model_builder, _expr1, _expr2) do
    unimplemented().on_unimplemented()
  end

  def add_greater_than_expr1_expr2_nif(_cp_model_builder, _expr1, _expr2) do
    unimplemented().on_unimplemented()
  end

  def only_enforce_if_nif(_constraint, _var) do
    unimplemented().on_unimplemented()
  end

  def add_abs_equal_nif(_builder, _var1, _var2) do
    unimplemented().on_unimplemented()
  end

  def add_abs_equal_constant_nif(_builder, _var1, _constant2) do
    unimplemented().on_unimplemented()
  end

  def add_all_different_nif(_builder, _var_list) do
    unimplemented().on_unimplemented()
  end

  def add_no_overlap_nif(_builder, _var_list) do
    unimplemented().on_unimplemented()
  end

  def bool_not_nif(_var) do
    unimplemented().on_unimplemented()
  end

  @spec solve_nif(any()) :: {any(), integer()}
  def solve_nif(_cp_model_builder) do
    unimplemented().on_unimplemented()
    {:ok, 1}
  end

  @spec solve_with_callback_nif(any(), pid()) :: {any(), integer()}
  def solve_with_callback_nif(_cp_model_builder, _pid) do
    unimplemented().on_unimplemented()
    {:ok, 1}
  end

  def solution_integer_value_nif(_cp_model_builder, _var) do
    unimplemented().on_unimplemented()
  end

  @spec solution_bool_value_nif(any(), any()) :: integer()
  def solution_bool_value_nif(_cp_model_builder, _var) do
    unimplemented().on_unimplemented()
    1
  end

  def sum_nif(_vars) do
    unimplemented().on_unimplemented()
  end

  def minus_nif(_expr1, _expr2) do
    unimplemented().on_unimplemented()
  end

  def prod_bool_var1_constant2_nif(_var1, _var2) do
    unimplemented().on_unimplemented()
  end

  def prod_int_var1_constant2_nif(_var1, _var2) do
    unimplemented().on_unimplemented()
  end

  def expr_from_bool_var_nif(_bool_var) do
    unimplemented().on_unimplemented()
  end

  def expr_from_int_var_nif(_int_var) do
    unimplemented().on_unimplemented()
  end

  def expr_from_constant_nif(_constant) do
    unimplemented().on_unimplemented()
  end

  def add_max_equality_nif(_builder_res, _name, _var_list) do
    unimplemented().on_unimplemented()
  end

  def add_minimize_nif(_builder_res, _name) do
    unimplemented().on_unimplemented()
  end

  def add_maximize_nif(_builder_res, _name) do
    unimplemented().on_unimplemented()
  end

  def add_decision_strategy_nif(
        _builder_res,
        _vars,
        _variable_selection_strategy,
        _domain_reduction_strategy
      ) do
    unimplemented().on_unimplemented()
  end

  defp unimplemented() do
    Application.get_env(:exhort, :unimplemented)
  end
end
