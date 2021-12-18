defmodule Exhort.SAT.Constraint do
  @moduledoc """
  A constraint on the model.
  """
  @type constraint :: :< | :<= | :== | :!= | :>= | :>

  @type t :: %__MODULE__{}
  defstruct [:res, :defn]
end
