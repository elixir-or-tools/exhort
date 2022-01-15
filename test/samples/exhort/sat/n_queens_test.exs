defmodule Samples.Exhort.SAT.NQueens do
  use ExUnit.Case
  use Exhort.SAT.Builder

  test "n-queens" do
    board_size = 4
    columns = 0..(board_size - 1)

    acc = %{
      builder: Builder.new(),
      queens: []
    }

    %{
      builder: builder,
      queens: queens
    } =
      Enum.reduce(columns, acc, fn column, %{builder: builder, queens: queens} = acc ->
        queen = "queen_#{column}"
        queens = queens ++ [queen]

        builder =
          builder
          |> Builder.def_int_var(queen, {0, board_size - 1})
          |> Builder.def_constant("#{column}", column)

        %{acc | builder: builder, queens: queens}
      end)

    builder = Builder.constrain_list(builder, :"all!=", queens)

    builder =
      Enum.reduce(columns, [], fn column, constraints = _acc ->
        queen = Map.get(builder.vars.map, "queen_#{column}")
        desc_diagonal = LinearExpression.sum(column, queen)
        constraints ++ [desc_diagonal]
      end)
      |> then(&Builder.constrain_list(builder, :"all!=", &1))

    builder =
      Enum.reduce(columns, [], fn column, constraints = _acc ->
        queen = Map.get(builder.vars.map, "queen_#{column}")
        asc_diagonal = LinearExpression.minus(column, queen)
        constraints ++ [asc_diagonal]
      end)
      |> then(&Builder.constrain_list(builder, :"all!=", &1))

    assert :optimal ==
             builder
             |> Builder.build()
             |> Model.solve()
             |> then(& &1.status)
  end
end
