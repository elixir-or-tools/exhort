defmodule Exhort.SAT.SolverResponse do
  @moduledoc """
  A response from solving a model.

  Provides functions for retrieving variable values from the response.
  """

  @type t :: %__MODULE__{}
  defstruct [:res, :model, :status, :int_status, :objective, :walltime, :usertime]

  alias __MODULE__
  alias Exhort.NIF.Nif
  alias Exhort.SAT.BoolVar
  alias Exhort.SAT.IntVar
  alias Exhort.SAT.Model
  alias Exhort.SAT.SolverResponse
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

  @doc """
  Get the corresponding value of the integer variable.
  """
  @spec int_val(SolverResponse.t(), literal :: String.t() | atom()) :: integer()
  def int_val(response, var) do
    SolverResponse.get_int_val(response, var)
  end

  @doc """
  Get the corresponding value of the boolean variable.
  """
  @spec bool_val(SolverResponse.t(), literal :: String.t() | atom() | BoolVar.t()) :: boolean()
  def bool_val(response, var) do
    SolverResponse.get_bool_val(response, var)
  end

  @spec get_int_val(SolverResponse.t(), var :: atom() | String.t() | IntVar.t()) ::
          nil | integer()
  def get_int_val(%SolverResponse{status: status}, _)
      when status in [:unknown, :model_invalid, :infeasible] do
    nil
  end

  def get_int_val(%SolverResponse{res: response_res, model: %{vars: vars}}, %IntVar{
        res: nil,
        name: literal
      }) do
    %IntVar{res: var_res} = Vars.get(vars, literal)
    Nif.solution_integer_value_nif(response_res, var_res)
  end

  def get_int_val(%SolverResponse{res: response_res}, %IntVar{res: var_res}) do
    Nif.solution_integer_value_nif(response_res, var_res)
  end

  def get_int_val(%SolverResponse{res: response_res, model: %{vars: vars}}, literal) do
    %IntVar{res: var_res} = Vars.get(vars, literal)
    Nif.solution_integer_value_nif(response_res, var_res)
  end

  @spec get_bool_val(SolverResponse.t(), var :: atom() | String.t() | BoolVar.t()) ::
          nil | boolean()
  def get_bool_val(%SolverResponse{status: status}, _)
      when status in [:unknown, :model_invalid, :infeasible] do
    nil
  end

  def get_bool_val(%SolverResponse{res: response_res, model: %{vars: vars}}, %BoolVar{
        res: nil,
        name: literal
      }) do
    %BoolVar{res: var_res} = Vars.get(vars, literal)
    Nif.solution_bool_value_nif(response_res, var_res) == 1
  end

  def get_bool_val(%SolverResponse{res: response_res}, %BoolVar{res: var_res}) do
    Nif.solution_bool_value_nif(response_res, var_res) == 1
  end

  def get_bool_val(%SolverResponse{res: response_res, model: %{vars: vars}}, literal) do
    %BoolVar{res: var_res} = Vars.get(vars, literal)
    Nif.solution_bool_value_nif(response_res, var_res) == 1
  end
end
