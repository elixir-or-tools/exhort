defmodule Exhort.SAT.Vars do
  @moduledoc """
  Hold the defined varaibles and raise an error if an undefined variable is
  referenced.
  """

  alias __MODULE__

  @type t :: __MODULE__
  defstruct list: [], map: %{}

  @doc """
  Add a variable, using the name in the struct for lookup.

  Variables are kept in order so when they are resolved, referenced variables
  are available.
  """
  @spec add(Vars.t(), %{name: String.t()}) :: Vars.t()
  def add(%Vars{list: list, map: map} = vars, %{name: name} = var) do
    %Vars{vars | list: list ++ [var], map: Map.put(map, name, var)}
  end

  @doc """
  Get a variable by name.
  """
  @spec get(Vars.t(), atom() | String.t()) :: any()
  def get(%Vars{map: map} = _vars, name) do
    case Map.get(map, name) do
      nil -> raise "Undefined variable: #{inspect(name)}"
      var -> var
    end
  end

  @doc """
  Provide an ordered list of variables.
  """
  def iter(%Vars{list: list}), do: list
end
