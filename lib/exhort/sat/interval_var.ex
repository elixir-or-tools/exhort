defmodule Exhort.SAT.IntervalVar do
  @moduledoc """
  An interval variable defined in the model.
  """

  alias __MODULE__

  @type t :: %__MODULE__{}
  defstruct [:res, :name, :start, :size, :stop, :opts]

  @doc """
  Define a new interval variable.

  - `name` - The variable name that may be referenced in other expressions.
  - `start` - The lower bound of the interval
  - `size` - The step size of the parts of the iterval
  - `stop` - The upper bound of the interval
  - `opts` - Supports `if: bool` as a condition on the interval constraint
  """
  @spec new(
          name :: String.t(),
          start :: atom() | String.t(),
          size :: integer(),
          stop :: atom() | String.t(),
          opts :: Keyword.t()
        ) ::
          IntervalVar.t()
  def new(name, start, size, stop, opts \\ []) do
    %IntervalVar{name: name, start: start, size: size, stop: stop, opts: opts}
  end
end
