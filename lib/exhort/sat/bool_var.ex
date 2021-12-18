defmodule Exhort.SAT.BoolVar do
  @moduledoc """
  A boolean variable defined in the model.
  """

  @type t :: %__MODULE__{}
  defstruct [:res, :name]
end
