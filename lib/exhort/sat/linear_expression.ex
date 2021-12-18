defmodule Exhort.SAT.LinearExpression do
  @moduledoc """
  An expression in terms of variables and operators, constraining the overall
  model.
  """

  @type t :: %__MODULE__{}
  defstruct res: nil, expr: []

  alias __MODULE__
  alias Exhort.NIF.Nif

  @doc """
  Apply the linear expression to the model.
  """
  @spec resolve(LinearExpression.t(), map()) :: LinearExpression.t()
  def resolve(%LinearExpression{expr: {:sum, atom1, %LinearExpression{} = sum_expr}} = expr, vars) do
    var1 = Map.get(vars, atom1)
    sum_expr = resolve(sum_expr, vars)

    expr_res = Nif.sum_int_var_expr_nif(var1.res, sum_expr.res)

    %LinearExpression{expr | res: expr_res, expr: {:sum, var1, sum_expr}}
  end

  def resolve(%LinearExpression{expr: {:sum, atom1, int2}} = expr, vars) when is_integer(int2) do
    var1 = Map.get(vars, atom1)
    expr_res = Nif.sum_int_var_constant_nif(var1.res, int2)

    %LinearExpression{expr | res: expr_res, expr: {:sum, var1, int2}}
  end

  def resolve(%LinearExpression{expr: {:sum, atom1, atom2}} = expr, vars) do
    var1 = Map.get(vars, atom1)
    var2 = Map.get(vars, atom2)
    expr_res = Nif.sum_nif(var1.res, var2.res)

    %LinearExpression{expr | res: expr_res}
  end

  def resolve(%LinearExpression{expr: {:minus, atom1, atom2}} = expr, vars) do
    var1 = Map.get(vars, atom1)
    var2 = Map.get(vars, atom2)
    expr_res = Nif.minus_nif(var1.res, var2.res)

    %LinearExpression{expr | res: expr_res}
  end

  def resolve(%LinearExpression{expr: {:prod, atom1, int2}} = expr, vars) when is_integer(int2) do
    var1 = Map.get(vars, atom1)
    expr_res = Nif.prod_nif(var1.res, int2)

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
  Create a linear expression as the sum of `var1` and `var2`.
  """
  @spec minus(atom() | String.t(), atom() | String.t()) :: LinearExpression.t()
  def minus(var1, var2) do
    %LinearExpression{expr: {:minus, var1, var2}}
  end

  @doc """
  Create a linear expression as the sum of `var1` and `var2`.
  """
  @spec prod(atom() | String.t(), atom() | String.t()) :: LinearExpression.t()
  def prod(var1, var2) do
    %LinearExpression{expr: {:prod, var1, var2}}
  end

  @doc """
  Create a linear expression from the given integer constant.
  """
  @spec constant(integer()) :: LinearExpression.t()
  def constant(int) do
    %LinearExpression{expr: {:constant, int}}
  end
end
