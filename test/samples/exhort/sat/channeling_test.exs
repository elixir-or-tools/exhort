defmodule Samples.Exhort.SAT.Channeling do
  use ExUnit.Case
  use Exhort.SAT.Builder

  test "channeling" do
    builder =
      Builder.new()
      |> Builder.def_int_var(:x, {0, 10})
      |> Builder.def_int_var(:y, {0, 10})
      |> Builder.def_bool_var(:b)
      |> Builder.constrain(:x >= 5, if: :b)
      |> Builder.constrain(:x < 5, unless: :b)
      |> Builder.constrain(:x + :y == 10, if: :b)
      |> Builder.constrain(:y == 0, unless: :b)

    {response, acc} =
      builder
      |> Builder.build()
      |> Model.solve(fn
        _response, nil -> 1
        _response, acc -> acc + 1
      end)

    assert response.status == :optimal
    assert 10 == SolverResponse.int_val(response, :x)
    assert 0 == SolverResponse.int_val(response, :y)
    assert SolverResponse.bool_val(response, :b)
    assert 11 == acc
  end
end
