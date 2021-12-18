defmodule Exhort.SAT.Constraint do
  @moduledoc """
  A constraint on the model.
  """
  @type constraint :: :< | :<= | :== | :!= | :>= | :> | :"abs==" | :"all!="

  @type t :: %__MODULE__{}
  defstruct [:res, :defn]
end
