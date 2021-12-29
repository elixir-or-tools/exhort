defmodule Samples.Exhort.SAT.SimpleSAT do
  use ExUnit.Case

  alias Exhort.SAT.SolverResponse
  alias Exhort.SAT.Model
  alias Exhort.SAT.ExpressionBuilder

  require ExpressionBuilder
  require SolverResponse

  test "simple sat program" do
    model =
      ExpressionBuilder.new()
      |> ExpressionBuilder.def_int_var(x, {0, 2})
      |> ExpressionBuilder.def_int_var(y, {0, 2})
      |> ExpressionBuilder.def_int_var(z, {0, 2})
      |> ExpressionBuilder.constrain(x != y)
      |> ExpressionBuilder.build()

    response = Model.solve(model)
    assert 1 == SolverResponse.int_var(response, x)
    assert 0 == SolverResponse.int_var(response, y)
    assert 0 == SolverResponse.int_var(response, z)
  end
end
