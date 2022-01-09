defmodule Exhort.SAT.IntVar do
  @moduledoc """
  An integer variable defined in the model.
  """

  alias __MODULE__

  @type t :: %__MODULE__{}
  defstruct [:res, :name, :domain]

  @spec new(name :: String.t(), domain :: {lower_bound :: integer(), upper_bound :: integer()}) ::
          IntVar.t()
  def new(name, domain) do
    %IntVar{name: name, domain: domain}
  end
end
