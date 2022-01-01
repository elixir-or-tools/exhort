defmodule Samples.Exhort.SAT.CpIsFun do
  use ExUnit.Case
  use Exhort.SAT.Builder

  test "CP is fun" do
    base = 10

    digit = {0, base - 1}
    non_zero_digit = {1, base - 1}

    builder =
      Builder.new()
      |> Builder.def_int_var("c", non_zero_digit)
      |> Builder.def_int_var("p", digit)
      |> Builder.def_int_var("i", non_zero_digit)
      |> Builder.def_int_var("s", digit)
      |> Builder.def_int_var("f", non_zero_digit)
      |> Builder.def_int_var("u", digit)
      |> Builder.def_int_var("n", digit)
      |> Builder.def_int_var("t", non_zero_digit)
      |> Builder.def_int_var("r", digit)
      |> Builder.def_int_var("e", digit)
      |> Builder.constrain_list(:"all!=", ["c", "p", "i", "s", "f", "u", "n", "t", "r", "e"])

      # CP + IS + FUN = TRUE
      |> Builder.constrain(
        "c" * ^base + "p" + "i" * ^base + "s" + "f" * ^base * ^base + "u" * ^base + "n" ==
          "t" * ^base * ^base * ^base + "r" * ^base * ^base + "u" * ^base + "e"
      )

    solution_callback = fn %SolverResponse{} = _response, acc ->
      # IO.write("C=#{SolverResponse.int_val(response, "c")} ")
      # IO.write("P=#{SolverResponse.int_val(response, "p")} ")
      # IO.write("I=#{SolverResponse.int_val(response, "i")} ")
      # IO.write("S=#{SolverResponse.int_val(response, "s")} ")
      # IO.write("F=#{SolverResponse.int_val(response, "f")} ")
      # IO.write("U=#{SolverResponse.int_val(response, "u")} ")
      # IO.write("N=#{SolverResponse.int_val(response, "n")} ")
      # IO.write("T=#{SolverResponse.int_val(response, "t")} ")
      # IO.write("R=#{SolverResponse.int_val(response, "r")} ")
      # IO.puts("E=#{SolverResponse.int_val(response, "e")}")
      acc
    end

    {_response, acc} =
      builder
      |> Builder.build()
      |> Model.solve(fn
        response, nil ->
          solution_callback.(response, [response])

        response, acc ->
          solution_callback.(response, [response | acc])
      end)

    assert 72 == length(acc)
  end
end
