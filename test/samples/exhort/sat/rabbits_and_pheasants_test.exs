defmodule Samples.Exhort.SAT.RabbitsAndPheasantsTest do
  use ExUnit.Case
  use Exhort.SAT.Builder

  test "rabbits and pheasants" do
    response =
      Builder.new()
      |> Builder.def_int_var(r, {0, 100})
      |> Builder.def_int_var(p, {0, 100})
      |> Builder.constrain(r + p == 20)
      |> Builder.constrain(4 * r + 2 * p == 56)
      |> Builder.build()
      |> Model.solve()

    assert :optimal = response.status
    assert 8 == SolverResponse.int_val(response, r)
    assert 12 == SolverResponse.int_val(response, p)
  end
end
