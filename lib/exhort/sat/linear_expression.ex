defmodule Exhort.SAT.LinearExpression do
  @type t :: %__MODULE__{}
  defstruct res: nil, expr: []

  alias __MODULE__
  alias Exhort.NIF.Nif

  @doc """
  Apply the linear expression to the model.
  """
  @spec resolve(LinearExpression.t(), map()) :: LinearExpression.t()
  def resolve(%LinearExpression{expr: {:sum, atom1, atom2}} = expr, vars) do
    var1 = Map.get(vars, atom1)
    var2 = Map.get(vars, atom2)
    expr_res = Nif.sum_nif(var1.res, var2.res)
    %LinearExpression{expr | res: expr_res}
  end

  @doc """
  Create a linear expression as the sum of `var1` and `var2`.
  """
  @spec sum(atom() | String.t(), atom() | String.t()) :: LinearExpression.t()
  def sum(var1, var2) do
    %LinearExpression{expr: {:sum, var1, var2}}
  end

  @doc """
  Create a linear expression from the given integer constant.
  """
  @spec constant(integer()) :: LinearExpression.t()
  def constant(int) do
    %LinearExpression{expr: {:constant, int}}
  end
end
