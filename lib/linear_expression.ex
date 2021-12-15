defmodule LinearExpression do
  defstruct res: nil, expr: []

  def resolve(%LinearExpression{expr: {:sum, atom1, atom2}} = expr, vars) do
    var1 = Map.get(vars, atom1)
    var2 = Map.get(vars, atom2)
    expr_res = Nif.sum_nif(var1.res, var2.res)
    %LinearExpression{expr | res: expr_res}
  end

  def sum(atom1, atom2) do
    %LinearExpression{expr: {:sum, atom1, atom2}}
  end

  def constant(int) do
    %LinearExpression{expr: {:constant, int}}
  end
end
