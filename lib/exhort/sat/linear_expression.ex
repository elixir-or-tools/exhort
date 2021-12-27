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
          expr: {:sum, expr_list}
        } = expr,
        vars
      )
      when is_list(expr_list) do
    expr_list
    |> Enum.map(&Vars.get(vars, &1))
    |> then(fn
      [%IntVar{} | _] = vars ->
        vars
        |> Enum.map(& &1.res)
        |> List.to_tuple()
        |> Nif.sum_int_vars_nif()

      [%BoolVar{} | _] = vars ->
        vars
        |> Enum.map(& &1.res)
        |> List.to_tuple()
        |> Nif.sum_bool_vars_nif()
    end)
    |> then(&%LinearExpression{expr | res: &1, expr: {:sum, expr_list}})
  end

  def resolve(
        %LinearExpression{
          res: nil,
          expr: {:sum, %LinearExpression{} = expr1, %LinearExpression{} = expr2}
        } = expr,
        vars
      ) do
    expr1 = resolve(expr1, vars)
    expr2 = resolve(expr2, vars)

    Nif.sum_expr1_expr2_nif(expr1.res, expr2.res)
    |> then(&%LinearExpression{expr | res: &1, expr: {:sum, expr1, expr2}})
  end

  def resolve(
        %LinearExpression{res: nil, expr: {:prod, %IntVar{} = var1, int2}} = expr,
        _vars
      )
      when is_integer(int2) do
    Nif.prod_int_var1_constant2_nif(var1.res, int2)
    |> then(&%LinearExpression{expr | res: &1})
  end

  def resolve(
        %LinearExpression{res: nil, expr: {:prod, list1, list2}} = expr,
        vars
      )
      when is_list(list1) and is_list(list2) do
    {
      list1
      |> Enum.map(&Vars.get(vars, &1))
      |> Enum.map(& &1.res),
      list2
    }
    |> then(fn {list1, list2} ->
      Nif.prod_list1_list2_nif(list1, list2)
    end)
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

    Nif.minus_expr1_expr2_nif(expr1.res, expr2.res)
    |> then(&%LinearExpression{expr | res: &1, expr: {:sum, expr1, expr2}})
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
end
