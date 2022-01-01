defmodule Samples.Exhort.SAT.BinpackingProblem do
  use ExUnit.Case
  use Exhort.SAT.Builder

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
          var = "x_#{item}_#{bin}"

          builder
          |> Builder.def_int_var(^var, {0, num_copies})
        end)
      end)
      |> Builder.reduce(all_bins, fn bin, builder ->
        load_bin = "load_#{bin}"
        Builder.def_int_var(builder, ^load_bin, {0, bin_capacity})
      end)
      |> Builder.reduce(all_bins, fn bin, builder ->
        slack_bin = "slack_#{bin}"
        Builder.def_bool_var(builder, ^slack_bin)
      end)
      |> Builder.reduce(all_bins, fn bin, builder ->
        expr = Enum.map(items, &{elem(&1, 0), "x_#{elem(&1, 0)}_#{bin}"})
        load_bin = "load_#{bin}"

        builder
        |> Builder.constrain(sum(for {item, x} <- ^expr, do: ^item * ^x) == ^load_bin)
      end)
      |> Builder.reduce(items, fn {item, num_copies}, builder ->
        x_i = Enum.map(all_bins, &"x_#{item}_#{&1}")

        builder
        |> Builder.constrain(sum(^x_i) == ^num_copies)
      end)
      |> Builder.reduce(all_bins, fn bin, builder ->
        safe_capacity = bin_capacity - slack_capacity

        load_bin = "load_#{bin}"
        slack_bin = "slack_#{bin}"

        builder
        |> Builder.constrain(^load_bin <= ^safe_capacity, if: ^slack_bin)
        |> Builder.constrain(^load_bin > ^safe_capacity, unless: ^slack_bin)
      end)
      |> then(fn builder ->
        bins = Enum.map(all_bins, &"slack_#{&1}")
        Builder.maximize(builder, sum(^bins))
      end)

    assert :optimal ==
             builder
             |> Builder.build()
             |> Model.solve()
             |> then(& &1.status)
  end
end
