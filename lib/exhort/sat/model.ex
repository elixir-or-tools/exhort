defmodule Exhort.SAT.Model do
  @moduledoc """
  The model built from the `Builder`.
  """

  @type t :: %__MODULE__{}
  defstruct [:res, :vars, :constraints]

  alias __MODULE__
  alias Exhort.NIF.Nif
  alias Exhort.SAT.SolverResponse
  alias Exhort.SAT.SolutonListener

  @doc """
  Solve the model, returning the solution.

  This may only be called after the `build` function has been called.
  """
  @spec solve(Model.t()) :: SolverResponse.t()
  def solve(%Model{res: res} = model) when not is_nil(res) do
    SolverResponse.build(Nif.solve_nif(model.res), model)
  end

  @doc """
  Solve the model, using a callback for each response to the model.

  The given function will be called on each improving feasible solution found
  during the search. For a non-optimization problem, if the option to find all
  solution was set, then this will be called on each new solution.
  """
  @spec solve(Model.t(), (SolverResponse.t(), any() -> any())) :: {SolverResponse.t(), any()}
  def solve(%Model{res: res} = model, callback) when not is_nil(res) do
    {:ok, pid} = SolutonListener.start_link(model, callback)

    response = SolverResponse.build(Nif.solve_with_callback_nif(model.res, pid), model)
    acc = SolutonListener.acc(pid)

    SolutonListener.stop(pid)

    {response, acc}
  end
end
