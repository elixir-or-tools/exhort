defmodule Exhort.SAT.SolverResponse do
  @moduledoc """
  A response from solving a model.

  Provides functions for retrieving variable values from the response.
  """

  @type t :: %__MODULE__{}
  defstruct [:res, :model, :status, :int_status, :objective, :walltime, :usertime]

  alias __MODULE__
  alias Exhort.NIF.Nif
  alias Exhort.SAT.IntVar
  alias Exhort.SAT.Model
  alias Exhort.SAT.Vars

  @spec build(map(), Model.t()) :: SolverResponse.t()
  def build(
        %{
          "res" => res,
          "status" => int_status,
          "objective" => objective,
          "walltime" => walltime,
          "usertime" => usertime
        },
        model
      ) do
    %SolverResponse{
      res: res,
      model: model,
      status: status_from_int(int_status),
      int_status: int_status,
      objective: objective,
      walltime: walltime,
      usertime: usertime
    }
  end

  def stats(response) do
    Map.take(response, [:status, :objective, :walltime, :usertime])
  end

  def status_from_int(int) do
    %{0 => :unknown, 1 => :model_invalid, 2 => :feasible, 3 => :infeasible, 4 => :optimal}
    |> Map.get(int)
  end

  def bool_val(%{status: status}, _atom) when status in [:unknown, :model_invalid, :infeasible],
    do: nil

  def bool_val(%{model: %{vars: vars}} = response, atom) do
    var = Vars.get(vars, atom)
    Nif.solution_bool_value_nif(response.res, var.res) == 1
  end

  def int_val(%{status: status}, _atom) when status in [:unknown, :model_invalid, :infeasible],
    do: nil

  def int_val(%SolverResponse{} = response, %IntVar{} = var) do
    Nif.solution_integer_value_nif(response.res, var.res)
  end

  def int_val(%SolverResponse{model: %{vars: vars}} = response, atom) do
    %IntVar{res: var_res} = Vars.get(vars, atom)
    Nif.solution_integer_value_nif(response.res, var_res)
  end
end
