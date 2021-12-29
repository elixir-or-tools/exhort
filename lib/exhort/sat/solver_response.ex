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

  @doc """
  Get the corresponding value of the boolean variable.
  """
  @spec bool_val(SolverResponse.t(), literal :: atom() | String.t()) :: nil | boolean()
  def bool_val(%{status: status}, _atom) when status in [:unknown, :model_invalid, :infeasible],
    do: nil

  def bool_val(%{model: %{vars: vars}} = response, atom) do
    var = Vars.get(vars, atom)
    Nif.solution_bool_value_nif(response.res, var.res) == 1
  end

  @doc """
  Get the corresponding value of the integer variable.
  """
  @spec int_val(SolverResponse.t(), literal :: atom() | String.t()) :: nil | integer()
  def int_val(%{status: status}, _atom) when status in [:unknown, :model_invalid, :infeasible],
    do: nil

  def int_val(%SolverResponse{} = response, %IntVar{} = var) do
    Nif.solution_integer_value_nif(response.res, var.res)
  end

  def int_val(%SolverResponse{model: %{vars: vars}} = response, literal)
      when is_atom(literal) or is_binary(literal) do
    %IntVar{res: var_res} = Vars.get(vars, literal)
    Nif.solution_integer_value_nif(response.res, var_res)
  end

  defmacro int_var(response_exp, var_exp) do
    var = transform(var_exp)

    quote do
      %SolverResponse{res: response_res, model: %{vars: vars}} = unquote(response_exp)
      %IntVar{res: var_res} = Vars.get(vars, unquote(var))
      Nif.solution_integer_value_nif(response_res, var_res)
    end
  end

  defmacro bool_var(response_exp, var_exp) do
    quote do
      %SolverResponse{res: response_res, model: %{vars: vars}} = unquote(response_exp)
      %BoolVar{res: var_res} = Vars.get(vars, unquote(transform(var_exp)))
      Nif.solution_bool_value_nif(response_res, var_res)
    end
  end

  defp transform({x, _, _}), do: x
end
