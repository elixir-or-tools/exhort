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

    builder = Builder.new()

    builder =
      items
      |> Enum.reduce(builder, fn {item, num_copies}, builder ->
        all_bins
        |> Enum.reduce(builder, fn bin, builder ->
          builder
          |> Builder.def_int_var("x_#{item}_#{bin}", {0, num_copies})
        end)
      end)

    builder =
      all_bins
      |> Enum.reduce(builder, fn bin, builder ->
        builder
        |> Builder.def_int_var("load_#{bin}", {0, bin_capacity})
      end)

    builder =
      all_bins
      |> Enum.reduce(builder, fn bin, builder ->
        builder
        |> Builder.def_bool_var("slack_#{bin}")
      end)

    builder =
      all_bins
      |> Enum.reduce(builder, fn bin, builder ->
        expr =
          items
          |> Enum.reduce(nil, fn
            {item, _num_copies}, nil ->
              LinearExpression.prod("x_#{item}_#{bin}", item)

            {item, _num_copies}, expr ->
              prod = LinearExpression.prod("x_#{item}_#{bin}", item)
              LinearExpression.sum(expr, prod)
          end)

        builder
        |> Builder.constrain(expr, :==, "load_#{bin}")
      end)

    builder =
      items
      |> Enum.reduce(builder, fn {item, num_copies}, builder ->
        x_i = Enum.map(all_bins, &"x_#{item}_#{&1}")

        builder
        |> Builder.constrain(LinearExpression.sum(x_i), :==, num_copies)
      end)

    safe_capacity = bin_capacity - slack_capacity

    builder =
      all_bins
      |> Enum.reduce(builder, fn bin, builder ->
        builder
        |> Builder.constrain("load_#{bin}", :<=, safe_capacity, if: "slack_#{bin}")
        |> Builder.constrain("load_#{bin}", :>, safe_capacity, unless: "slack_#{bin}")
      end)

    builder = Builder.maximize(builder, LinearExpression.sum(Enum.map(all_bins, &"slack_#{&1}")))

    assert :optimal ==
             builder
             |> Builder.build()
             |> Model.solve()
             |> then(& &1.status)
  end
end
