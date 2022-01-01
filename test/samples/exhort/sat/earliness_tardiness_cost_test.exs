defmodule Samples.Exhort.SAT.EarlinessTardinessCostTest do
  use ExUnit.Case
  use Exhort.SAT.Builder

  test "earliness tardiness" do
    earliness_date = 5
    earliness_cost = 8
    lateness_date = 15
    lateness_cost = 12
    large_constant = 1000

    builder =
      Builder.new()
      |> Builder.def_int_var("x", {0, 20})
      |> Builder.def_int_var("expr", {0, large_constant})
      |> Builder.def_int_var("s1", {-large_constant, large_constant})
      |> Builder.def_constant("earliness_date", earliness_date)
      |> Builder.def_constant("earliness_cost", earliness_cost)
      |> Builder.def_constant("lateness_date", lateness_date)
      |> Builder.def_constant("lateness_cost", lateness_cost)
      |> Builder.constrain(
        "s1",
        :==,
        LinearExpression.terms([{-earliness_cost, "x"}, {earliness_cost, "earliness_date"}])
      )
      |> Builder.def_constant("s2", 0)
      |> Builder.def_int_var("s3", {-large_constant, large_constant})
      |> Builder.constrain(
        "s3",
        :==,
        LinearExpression.terms([{lateness_cost, "x"}, {-lateness_cost, "lateness_date"}])
      )
      |> Builder.max_equality("expr", ["s1", "s2", "s3"])
      |> Builder.decision_strategy(["x"], :choose_first, :select_min_value)

    solution_callback = fn %SolverResponse{} = response, acc ->
      # IO.puts(
      #  "x=#{SolverResponse.int_val(response, "x")}, expr=#{SolverResponse.int_val(response, "expr")}"
      # )

      [response | acc]
    end

    assert :optimal ==
             builder
             |> Builder.build()
             |> Model.solve(fn
               response, nil ->
                 solution_callback.(response, [response])

               response, acc ->
                 solution_callback.(response, [response | acc])
             end)
             |> elem(0)
             |> then(& &1.status)
  end
end
