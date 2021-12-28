defmodule Exhort.SAT.LinearExpression do
  @moduledoc """
  An expression in terms of variables and operators, constraining the overall
  model.

  The approach here is to transform values into `LinearExpression`s and then
  apply the operator (e.g., `:sum`) to the expressions. This allows for fewer
  NIF functions do the combination of the number of arguments.
  """

  @type t :: %__MODULE__{}
  defstruct res: nil, expr: [], expressions: []

  alias __MODULE__
  alias Exhort.NIF.Nif
  alias Exhort.SAT.BoolVar
  alias Exhort.SAT.IntVar
  alias Exhort.SAT.Vars

  @type eterm :: atom() | String.t() | LinearExpression.t()

  @doc """
  Apply the linear expression to the model.
  """
  @spec resolve(LinearExpression.t() | IntVar.t() | integer(), map()) :: LinearExpression.t()
  def resolve(
        %LinearExpression{
          res: nil,
          expr: {:sum, sum_list}
        } = expr,
        vars
      )
      when is_list(sum_list) do
    resolve_sum(expr, sum_list, vars)
  end

  def resolve(
        %LinearExpression{
          res: nil,
          expr: {:sum, %LinearExpression{} = expr1, %LinearExpression{} = expr2}
        } = expr,
        vars
      ) do
    sum_list = [expr1, expr2]
    resolve_sum(expr, sum_list, vars)
  end

  def resolve(%LinearExpression{res: nil, expr: {:prod, %BoolVar{} = var1, int2}} = expr, _vars)
      when is_integer(int2) do
    Nif.prod_bool_var1_constant2_nif(var1.res, int2)
    |> then(&%LinearExpression{expr | res: &1})
  end

  def resolve(
        %LinearExpression{res: nil, expr: {:prod, %IntVar{} = var1, int2}} = expr,
        _vars
      )
      when is_integer(int2) do
    Nif.prod_int_var1_constant2_nif(var1.res, int2)
    |> then(&%LinearExpression{expr | res: &1})
  end

  def resolve(%LinearExpression{res: nil, expr: {:prod, sym1, int2}} = expr, vars)
      when not is_integer(sym1) and is_integer(int2) do
    var1 = Vars.get(vars, sym1)

    resolve(%LinearExpression{expr | expr: {:prod, var1, int2}}, vars)
  end

  def resolve(%LinearExpression{res: nil, expr: {:prod, int1, sym2}} = expr, vars)
      when is_integer(int1) and not is_integer(sym2) do
    var2 = Vars.get(vars, sym2)

    resolve(%LinearExpression{expr | expr: {:prod, var2, int1}}, vars)
  end

  def resolve(
        %LinearExpression{
          res: nil,
          expr: {:minus, %LinearExpression{} = expr1, %LinearExpression{} = expr2}
        } = expr,
        vars
      ) do
    expr1 = resolve(expr1, vars)
    expr2 = resolve(expr2, vars)

    Nif.minus_nif(expr1.res, expr2.res)
    |> then(&%LinearExpression{expr | res: &1, expr: {:minus, expr1, expr2}})
  end

  def resolve(
        %LinearExpression{res: nil, expr: {opr, %IntVar{} = var1, %LinearExpression{} = expr2}} =
          expr,
        vars
      ) do
    %LinearExpression{} = expr1 = resolve(var1, vars)
    %LinearExpression{} = expr2 = resolve(expr2, vars)
    resolve(%LinearExpression{expr | expr: {opr, expr1, expr2}}, vars)
  end

  def resolve(
        %LinearExpression{res: nil, expr: {opr, %LinearExpression{} = expr1, %IntVar{} = var2}} =
          expr,
        vars
      ) do
    resolve(%LinearExpression{expr | expr: {opr, expr1, var2}}, vars)
  end

  def resolve(
        %LinearExpression{res: nil, expr: {opr, %IntVar{} = var1, %IntVar{} = var2}} = expr,
        vars
      ) do
    %LinearExpression{} = expr1 = resolve(var1, vars)
    %LinearExpression{} = expr2 = resolve(var2, vars)
    resolve(%LinearExpression{expr | expr: {opr, expr1, expr2}}, vars)
  end

  def resolve(
        %LinearExpression{res: nil, expr: {opr, %LinearExpression{} = var1, int2}} = expr,
        vars
      )
      when is_integer(int2) do
    %LinearExpression{} = expr1 = resolve(var1, vars)
    %LinearExpression{} = expr2 = resolve(int2, vars)

    resolve(%LinearExpression{expr | expr: {opr, expr1, expr2}}, vars)
  end

  def resolve(
        %LinearExpression{res: nil, expr: {opr, int1, %LinearExpression{} = var2}} = expr,
        vars
      ) do
    resolve(%LinearExpression{expr | expr: {opr, var2, int1}}, vars)
  end

  def resolve(%LinearExpression{res: nil, expr: {opr, sym1, sym2}} = expr, vars) do
    expr1 = resolve(sym1, vars)
    expr2 = resolve(sym2, vars)
    resolve(%LinearExpression{expr | expr: {opr, expr1, expr2}}, vars)
  end

  def resolve(%LinearExpression{} = expr, _vars), do: expr

  def resolve(%BoolVar{} = var, _vars) do
    var
    |> then(&Nif.expr_from_bool_var_nif(&1.res))
    |> then(&%LinearExpression{res: &1, expr: var})
  end

  def resolve(%IntVar{} = var, _vars) do
    var
    |> then(&Nif.expr_from_int_var_nif(&1.res))
    |> then(&%LinearExpression{res: &1, expr: var})
  end

  def resolve(val, _vars) when is_integer(val) do
    val
    |> then(&Nif.expr_from_constant_nif(&1))
    |> then(&%LinearExpression{res: &1, expr: val})
  end

  def resolve(val, vars) when is_atom(val) or is_binary(val) do
    vars
    |> Vars.get(val)
    |> resolve(vars)
  end

  @spec resolve_sum(LinearExpression.t(), list(), map()) :: LinearExpression.t()
  defp resolve_sum(expr, sum_list, vars) do
    sum_list
    |> Enum.map(fn item ->
      case item do
        %LinearExpression{} = item -> item
        _ -> Vars.get(vars, item)
      end
    end)
    |> Enum.map(fn expr ->
      expr = resolve(expr, vars)
      expr.res
    end)
    |> List.to_tuple()
    |> Nif.sum_nif()
    |> then(&%LinearExpression{expr | res: &1, expr: {:sum, sum_list}})
  end

  @doc """
  Create a linear expression as the sum of the list of provided variables.
  """
  @spec sum([eterm()]) :: LinearExpression.t()
  def sum(vars) when is_list(vars) do
    %LinearExpression{expr: {:sum, vars}}
  end

  @doc """
  Create a linear expression as the sum of `var1` and `var2`.
  """
  @spec sum(eterm(), eterm()) :: LinearExpression.t()
  def sum(var1, var2) do
    %LinearExpression{expr: {:sum, var1, var2}}
  end

  @doc """
  Create a linear expression as the difference of `var1` and `var2`.
  """
  @spec minus(eterm(), eterm()) :: LinearExpression.t()
  def minus(var1, var2) do
    %LinearExpression{expr: {:minus, var1, var2}}
  end

  @doc """
  Create a linear expression as the product of `val1` and `val2`.
  """
  @spec prod(IntVar.t() | integer() | list(), IntVar.t() | integer() | list()) ::
          LinearExpression.t()
  def prod(val1, val2) when is_list(val1) and is_list(val2) do
    Enum.zip(val1, val2)
    |> Enum.map(&prod(elem(&1, 0), elem(&1, 1)))
    |> then(&%LinearExpression{expr: {:sum, &1}})
  end

  def prod(val1, val2) do
    %LinearExpression{expr: {:prod, val1, val2}}
  end

  @doc """
  Create a linear expression from the given integer constant.
  """
  @spec constant(integer()) :: LinearExpression.t()
  def constant(int) do
    %LinearExpression{expr: {:constant, int}}
  end

  @doc """
  Create an expression from the given `items`. Each expression is created using
  `term_fn` and joined using `join_fn`.
  """
  def terms(items, term_fn, join_fn) do
    items
    |> Enum.reduce(nil, fn
      item, nil ->
        term_fn.(item)

      item, expr ->
        term = term_fn.(item)
        join_fn.(expr, term)
    end)
  end

  @doc """
  Create an expression from the given list of terms. Each term is is a two-value
  tuple. The first element of the tuple is a constant coefficient. The second
  element is an integer variable.

  ```
  [{3, :x}, {4, :y}, {5, :z}] => 3*x + 4*y + 5*z
  ```
  """
  @spec terms([{integer(), atom() | String.t()}]) :: LinearExpression.t()
  def terms(items) do
    Enum.unzip(items)
    |> then(fn {coeff, vars} ->
      prod(vars, coeff)
    end)
  end
end
