defmodule LinearExpression do
  @on_load :load_nifs

  defstruct res: nil, expr: []

  def load_nifs do
    :erlang.load_nif('priv/lib/linear_expression', 0)
  end

  def sum(atom1, atom2) do
    %LinearExpression{expr: {:sum, atom1, atom2}}
  end

  def constant(int) do
    %LinearExpression{expr: {:constant, int}}
  end

  def sum_nif(_var1, _var2) do
  end
end
