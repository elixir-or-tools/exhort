defmodule Samples.Exhort.SAT.MultipleKnapsack do
  use ExUnit.Case
  use Exhort.SAT.Builder

  test "multiple knapsack" do
    weights = [48, 30, 42, 36, 36, 48, 42, 42, 36, 24, 30, 30, 42, 36, 36]
    values = [10, 30, 25, 50, 35, 30, 15, 40, 30, 35, 45, 10, 20, 30, 25]
    assert length(weights) == length(values)
    num_items = length(weights)
    all_items = 0..(num_items - 1)

    bin_capacities = [100, 100, 100, 100, 100]
    num_bins = length(bin_capacities)
    all_bins = 0..(num_bins - 1)

    acc = %{
      builder: Builder.new(),
      x: []
    }

    %{
      builder: builder,
      x: x
    } =
      Enum.reduce(all_items, acc, fn item, acc ->
        Enum.reduce(all_bins, acc, fn bin, %{builder: builder, x: x} = acc ->
          x = x ++ [{item, bin}]
          builder = Builder.def_bool_var(builder, "x_#{item}_#{bin}")

          %{
            acc
            | builder: builder,
              x: x
          }
        end)
      end)

    builder =
      Enum.reduce(all_items, builder, fn item, builder ->
        x_options = Enum.filter(x, fn {i, _b} -> i == item end)
        x_option_vars = Enum.map(x_options, fn {i, b} -> "x_#{i}_#{b}" end)

        total_x = LinearExpression.sum(x_option_vars)
        Builder.constrain(builder, ^total_x <= 1)
      end)

    builder =
      Enum.reduce(all_bins, builder, fn bin, builder ->
        bin_weight =
          Enum.reduce(all_items, [], fn item, acc ->
            x_var = "x_#{item}_#{bin}"
            weight = Enum.at(weights, item)
            acc ++ [LinearExpression.prod(x_var, weight)]
          end)

        total_bin_weight = LinearExpression.sum(bin_weight)
        bin_capacity = Enum.at(bin_capacities, bin)
        Builder.constrain(builder, ^total_bin_weight <= ^bin_capacity)
      end)

    builder =
      Enum.reduce(all_bins, [], fn bin, acc ->
        Enum.reduce(all_items, acc, fn item, acc ->
          value = Enum.at(values, item)
          acc ++ [LinearExpression.prod("x_#{item}_#{bin}", value)]
        end)
      end)
      |> then(fn list ->
        Builder.maximize(builder, sum(^list))
      end)

    solver =
      builder
      |> Builder.build()
      |> Model.solve()

    assert solver.status == :optimal
    assert solver.objective == 395
  end
end
