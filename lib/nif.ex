defmodule Nif do
  @moduledoc """
  Interface to all the NIF implementations.
  """
  @on_load :load_nifs

  def load_nifs do
    :erlang.load_nif('priv/lib/nif', 0)
  end

  def new_builder_nif do
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

  def add_less_nif(_cp_model_builder, _var1, _var2) do
  end

  def add_less_or_equal_nif(_cp_model_builder, _var1, _var2) do
  end

  def only_enforce_if_nif(_constraint, _var) do
  end

  def bool_not_nif(_var) do
  end

  @spec solve_nif(any()) :: {any(), integer()}
  def solve_nif(_cp_model_builder) do
    {:any, 0}
  end

  def solution_integer_value_nif(_cp_model_builder, _var) do
  end

  @spec solution_bool_value_nif(any(), any()) :: integer()
  def solution_bool_value_nif(_cp_model_builder, _var) do
    1
  end

  def sum_nif(_var1, _var2) do
  end
end
