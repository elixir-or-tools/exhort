defmodule Samples.Exhort.SAT.SimpleSAT do
  use ExUnit.Case
  use Exhort.SAT.Builder

  test "simple sat program" do
    model =
      Builder.new()
      |> Builder.def_int_var(x, {0, 2})
      |> Builder.def_int_var(y, {0, 2})
      |> Builder.def_int_var(z, {0, 2})
      |> Builder.constrain(x != y)
      |> Builder.build()

    response = Model.solve(model)
    assert 1 == SolverResponse.int_val(response, x)
    assert 0 == SolverResponse.int_val(response, y)
    assert 0 == SolverResponse.int_val(response, z)
  end
end
