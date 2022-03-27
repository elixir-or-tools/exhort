defmodule Exhort do
  @moduledoc """
  Exhort is an idomatic Elixir interface to the Google OR Tools.

  The primary API for Exhort is through a few modules:

  * `Exhort.SAT.Builder` - The module and struct for building a
  `Exhort.SAT.Model`. The builder provides functions for defining variables,
  expressions and building the model.

  * `Exhort.SAT.Expr` - A factory for expressions, constraints and variables.
    This module may be used as the primary interface for defining the parts of a
    model which are then added to a `%Exhort.SAT.Builder{}` struct before
    building the model.

  * `Exhort.SAT.Model` - The result of building a model through
    `Exhort.SAT.Builder.build/1`. Solving the model is done with
    `Exhort.SAT.Model.solve/1` or `Exhort.SAT.Model.solve/2`. The latter accepts
    a function that receives intermediate results in the solution.

  * `Exhort.SAT.SolverResponse` - A model solution. The
    `%Exhort.SAT.SolverResponse{}` struct containts meta-level information of
    the solution. The module has functions for retriving the values of variables
    definied in the model.
  """
end
