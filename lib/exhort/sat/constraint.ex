defmodule Exhort.SAT.Constraint do
  @moduledoc """
  A constraint on the model.

  The binary constraints are:

  ```
  :< | :<= | :== | :>= | :> | :"abs=="
  ```

  The list constraints are:

  ```
  :"all!=" | :no_overlap
  ```
  """
  @type constraint :: :< | :<= | :== | :>= | :> | :"abs==" | :"all!=" | :no_overlap

  @type t :: %__MODULE__{}
  defstruct [:res, :defn]
end
