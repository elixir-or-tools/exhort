defmodule Exhort.SAT.BoolVar do
  @moduledoc """
  A boolean variable defined in the model.
  """

  alias __MODULE__
  alias Exhort.SAT.LinearExpression
  alias Exhort.NIF.Nif
  alias Exhort.SAT.Vars

  @type t :: %__MODULE__{}
  defstruct [:res, :name]

  @doc """
  Define a new boolean variable. In the model, true and false are represented as
  1 and 0, respectively.

  - `name` - The variable name that may be referenced in other expressions.
  """
  @spec new(name :: String.t()) :: BoolVar.t()
  def new(name) do
    %BoolVar{name: name}
  end

  @doc false
  @spec resolve(var :: atom() | String.t() | BoolVar.t(), map()) :: BoolVar.t()
  def resolve(
        %LinearExpression{res: nil, expr: {:not, %BoolVar{res: nil} = var}},
        vars
      ) do
    var = Vars.get(vars, var)
    %BoolVar{res: Nif.bool_not_nif(var.res), name: "not #{var.name}"}
  end

  def resolve(
        %LinearExpression{res: nil, expr: {:not, %BoolVar{} = var}},
        _vars
      ) do
    %BoolVar{res: Nif.bool_not_nif(var.res), name: "not #{var.name}"}
  end

  def resolve(
        %LinearExpression{res: nil, expr: {:not, literal}},
        vars
      ) do
    var = Vars.get(vars, literal)
    %BoolVar{res: Nif.bool_not_nif(var.res), name: "not #{var.name}"}
  end

  def resolve(%BoolVar{res: nil} = var, vars) do
    Vars.get(vars, var)
  end

  def resolve(%BoolVar{} = var, _vars) do
    var
  end

  def resolve(literal, vars) do
    vars
    |> Vars.get(literal)
    |> resolve(vars)
  end
end
