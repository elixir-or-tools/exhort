defmodule Model do
  @moduledoc """
  The model built from the `CpModelBuilder`.
  """

  @type t :: %__MODULE__{}
  defstruct [:res, :vars, :constraints]

  @doc """
  Solve the model, returning the solution.

  This may only be called after the `build` function has been called.
  """
  @spec solve(Model.t()) :: CpSolverResponse.t()
  def solve(%Model{res: res} = model) when not is_nil(res) do
    CpSolverResponse.build(Nif.solve_nif(model.res), model)
  end

  @doc """
  Solve the model, using a callback for each response to the model.

  The given function will be called on each improving feasible solution found
  during the search. For a non-optimization problem, if the option to find all
  solution was set, then this will be called on each new solution.
  """
  @spec solve(Model.t(), (CpSolverResponse.t(), any() -> any())) :: {CpSolverResponse.t(), any()}
  def solve(%Model{res: res} = model, callback) when not is_nil(res) do
    {:ok, pid} = SolutonListener.start_link(model, callback)

    response = CpSolverResponse.build(Nif.solve_with_callback_nif(model.res, pid), model)
    acc = SolutonListener.acc(pid)

    SolutonListener.stop(pid)

    {response, acc}
  end
end
