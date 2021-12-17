defmodule IntVar do
  @moduledoc """
  An integer variable defined in the model.
  """

  @type t :: %__MODULE__{}
  defstruct [:res, :name, :domain]
end
