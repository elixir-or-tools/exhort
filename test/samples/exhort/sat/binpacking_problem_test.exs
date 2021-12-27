defmodule Samples.Exhort.SAT.BinpackingProblem do
  use ExUnit.Case

  alias Exhort.SAT.Builder
  alias Exhort.SAT.LinearExpression
  alias Exhort.SAT.Model

  test "binpacking" do
    bin_capacity = 100
    slack_capacity = 20
    num_bins = 5
    all_bins = Range.new(1, num_bins)

    items = [{20, 6}, {15, 6}, {30, 4}, {45, 3}]

    builder =
      Builder.new()
      |> Builder.reduce(items, fn {item, num_copies}, builder ->
        builder
        |> Builder.reduce(all_bins, fn bin, builder ->
          builder
          |> Builder.def_int_var("x_#{item}_#{bin}", {0, num_copies})
        end)
      end)
      |> Builder.reduce(all_bins, &Builder.def_int_var(&2, "load_#{&1}", {0, bin_capacity}))
      |> Builder.reduce(all_bins, &Builder.def_bool_var(&2, "slack_#{&1}"))
      |> Builder.reduce(all_bins, fn bin, builder ->
        expr =
          items
          |> Enum.map(&{elem(&1, 0), "x_#{elem(&1, 0)}_#{bin}"})
          |> LinearExpression.terms()

        builder
        |> Builder.constrain(expr, :==, "load_#{bin}")
      end)
      |> Builder.reduce(items, fn {item, num_copies}, builder ->
        x_i = Enum.map(all_bins, &"x_#{item}_#{&1}")

        builder
        |> Builder.constrain(LinearExpression.sum(x_i), :==, num_copies)
      end)
      |> Builder.reduce(all_bins, fn bin, builder ->
        safe_capacity = bin_capacity - slack_capacity

        builder
        |> Builder.constrain("load_#{bin}", :<=, safe_capacity, if: "slack_#{bin}")
        |> Builder.constrain("load_#{bin}", :>, safe_capacity, unless: "slack_#{bin}")
      end)
      |> Builder.maximize(LinearExpression.sum(Enum.map(all_bins, &"slack_#{&1}")))

    assert :optimal ==
             builder
             |> Builder.build()
             |> Model.solve()
             |> then(& &1.status)
  end
end
