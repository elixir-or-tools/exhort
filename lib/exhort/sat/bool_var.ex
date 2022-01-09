defmodule Exhort.SAT.BoolVar do
  @moduledoc """
  A boolean variable defined in the model.
  """

  alias __MODULE__

  @type t :: %__MODULE__{}
  defstruct [:res, :name]

  @doc """
  Define a new boolean variable. In the model, true and false are represented as
  1 and 0, respectively.

  - `name` - The variable name that may be referenced in other expressions.
  - `domain` - The upper and lower bounds of the variable defined as a tuple,
    `{lower_bound, upper_bound}`.
  """
  @spec new(name :: String.t()) :: BoolVar.t()
  def new(name) do
    %BoolVar{name: name}
  end
end
