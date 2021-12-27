defmodule Samples.Exhort.SAT.RabbitsAndPheasantsTest do
  use ExUnit.Case

  alias Exhort.SAT.Builder
  alias Exhort.SAT.LinearExpression
  alias Exhort.SAT.Model
  alias Exhort.SAT.SolverResponse

  test "rabbits and pheasants" do
    response =
      Builder.new()
      |> Builder.def_int_var("r", {0, 100})
      |> Builder.def_int_var("p", {0, 100})
      |> Builder.constrain(LinearExpression.sum(["r", "p"]), :==, 20)
      |> Builder.constrain(LinearExpression.prod(["r", "p"], [4, 2]), :==, 56)
      |> Builder.build()
      |> Model.solve()

    assert :optimal = response.status
    assert 8 == SolverResponse.int_val(response, "r")
    assert 12 == SolverResponse.int_val(response, "p")
  end
end
