defmodule Exhort.SAT.IntervalVar do
  @moduledoc """
  An interval variable defined in the model.
  """

  @type t :: %__MODULE__{}
  defstruct [:res, :name, :start, :size, :stop]
end
