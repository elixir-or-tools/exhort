defmodule Samples.Exhort.SAT.RabbitsAndPheasantsTest do
  use ExUnit.Case

  alias Exhort.SAT.ExpressionBuilder
  alias Exhort.SAT.Model
  alias Exhort.SAT.SolverResponse

  require Exhort.SAT.ExpressionBuilder
  require Exhort.SAT.SolverResponse

  test "rabbits and pheasants" do
    response =
      ExpressionBuilder.new()
      |> ExpressionBuilder.def_int_var(r, {0, 100})
      |> ExpressionBuilder.def_int_var(p, {0, 100})
      |> ExpressionBuilder.constrain(r + p == 20)
      |> ExpressionBuilder.constrain(4 * r + 2 * p == 56)
      |> ExpressionBuilder.build()
      |> Model.solve()

    assert :optimal = response.status
    assert 8 == SolverResponse.int_var(response, r)
    assert 12 == SolverResponse.int_var(response, p)
  end
end
