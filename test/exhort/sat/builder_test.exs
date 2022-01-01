defmodule Exhort.SAT.BuilderTest do
  use ExUnit.Case
  use Exhort.SAT.Builder

  test "new int var" do
    model = Builder.new()
    assert Builder.def_int_var(model, "x", {0, 2})
  end

  test "not" do
    {x, y, b} =
      Builder.new()
      |> Builder.def_bool_var(:b)
      |> Builder.def_int_var(:x, {0, 1})
      |> Builder.def_int_var(:y, {0, 1})
      |> Builder.constrain(:x, :!=, :y)
      |> Builder.constrain(:x, :==, 1, if: :b)
      |> Builder.constrain(:y, :==, 1, unless: :b)
      |> Builder.build()
      |> Model.solve()
      |> then(
        &{SolverResponse.int_val(&1, :x), SolverResponse.int_val(&1, :y),
         SolverResponse.bool_val(&1, :b)}
      )

    assert {0, 1, false} = {x, y, b}
  end

  test "new bool var" do
    model = Builder.new()
    assert Builder.def_bool_var(model, "x")
  end

  test "equal" do
    model =
      Builder.new()
      |> Builder.def_int_var("x", {0, 2})
      |> Builder.def_int_var("y", {0, 2})

    assert Builder.constrain(model, "x", :==, "y")
  end

  test "not equal" do
    model =
      Builder.new()
      |> Builder.def_int_var("x", {0, 2})
      |> Builder.def_int_var("y", {0, 2})

    assert Builder.constrain(model, :x, :!=, :y)
  end

  test "solve" do
    model =
      Builder.new()
      |> Builder.def_int_var("x", {0, 2})
      |> Builder.def_int_var("y", {0, 2})
      |> Builder.constrain("x", :!=, "y")
      |> Builder.build()

    assert %SolverResponse{} = Model.solve(model)
  end

  test "solution int value" do
    model =
      Builder.new()
      |> Builder.def_int_var("x", {0, 2})
      |> Builder.def_int_var("y", {0, 2})
      |> Builder.def_int_var("z", {0, 2})
      |> Builder.constrain("x", :!=, "y")
      |> Builder.build()

    response = Model.solve(model)
    assert 1 == SolverResponse.int_val(response, "x")
  end

  test "simple sat program with DSL" do
    # Pure functions, pure Elixir
    builder =
      Builder.new()
      |> Builder.def_int_var(:x, {0, 2})
      |> Builder.def_int_var(:y, {0, 2})
      |> Builder.def_int_var(:z, {0, 2})
      |> Builder.constrain(:x, :!=, :y)

    # Interacting with the underlying CP Model
    response =
      builder
      |> Builder.build()
      |> Model.solve()

    assert 1 == SolverResponse.int_val(response, :x)
    assert 0 == SolverResponse.int_val(response, :y)
    assert 0 == SolverResponse.int_val(response, :z)
  end

  test "simple bool without DSL" do
    builder =
      Builder.new()
      |> Builder.def_bool_var("x")
      |> Builder.def_bool_var("y")
      |> Builder.constrain("x", :!=, "y")

    # Interacting with the underlying CP Model
    response =
      builder
      |> Builder.build()
      |> Model.solve()

    assert SolverResponse.bool_val(response, "x")
    refute SolverResponse.bool_val(response, "y")
  end

  test "simple bool DSL" do
    # Pure functions, pure Elixir
    builder =
      Builder.new()
      |> Builder.def_bool_var(:x)
      |> Builder.def_bool_var(:y)
      |> Builder.constrain(:x, :!=, :y)

    # Interacting with the underlying CP Model
    response =
      builder
      |> Builder.build()
      |> Model.solve()

    assert SolverResponse.bool_val(response, :x)
    refute SolverResponse.bool_val(response, :y)
  end
end
