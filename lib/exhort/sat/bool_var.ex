defmodule Exhort.SAT.BoolVar do
  @moduledoc """
  A boolean variable defined in the model.
  """

  alias __MODULE__

  @type t :: %__MODULE__{}
  defstruct [:res, :name]

  @spec new(name :: String.t()) :: BoolVar.t()
  def new(name) do
    %BoolVar{name: name}
  end
end
