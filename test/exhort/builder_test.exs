defmodule Exhort.SAT.BuilderTest do
  use ExUnit.Case

  alias Exhort.SAT.Builder
  alias Exhort.SAT.LinearExpression
  alias Exhort.SAT.Model
  alias Exhort.SAT.SolverResponse

  test "new int var" do
    model = Builder.new()
    assert Builder.def_int_var(model, "x", {0, 2})
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

    assert Builder.constrain(model, :==, "x", "y")
  end

  test "not equal" do
    model =
      Builder.new()
      |> Builder.def_int_var("x", {0, 2})
      |> Builder.def_int_var("y", {0, 2})

    assert Builder.constrain(model, :!=, :x, :y)
  end

  test "solve" do
    model =
      Builder.new()
      |> Builder.def_int_var("x", {0, 2})
      |> Builder.def_int_var("y", {0, 2})
      |> Builder.constrain(:!=, "x", "y")
      |> Builder.build()

    assert %SolverResponse{} = Model.solve(model)
  end

  test "solution int value" do
    model =
      Builder.new()
      |> Builder.def_int_var("x", {0, 2})
      |> Builder.def_int_var("y", {0, 2})
      |> Builder.def_int_var("z", {0, 2})
      |> Builder.constrain(:!=, "x", "y")
      |> Builder.build()

    response = Model.solve(model)
    assert 1 == SolverResponse.int_val(response, "x")
  end

  test "simple sat program" do
    model =
      Builder.new()
      |> Builder.def_int_var("x", {0, 2})
      |> Builder.def_int_var("y", {0, 2})
      |> Builder.def_int_var("z", {0, 2})
      |> Builder.constrain(:!=, "x", "y")
      |> Builder.build()

    response = Model.solve(model)
    assert 1 == SolverResponse.int_val(response, "x")
    assert 0 == SolverResponse.int_val(response, "y")
    assert 0 == SolverResponse.int_val(response, "z")
  end

  test "simple sat program with DSL" do
    # Pure functions, pure Elixir
    builder =
      Builder.new()
      |> Builder.def_int_var(:x, {0, 2})
      |> Builder.def_int_var(:y, {0, 2})
      |> Builder.def_int_var(:z, {0, 2})
      |> Builder.constrain(:!=, :x, :y)

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
      |> Builder.constrain(:!=, "x", "y")

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
      |> Builder.constrain(:!=, :x, :y)

    # Interacting with the underlying CP Model
    response =
      builder
      |> Builder.build()
      |> Model.solve()

    assert SolverResponse.bool_val(response, :x)
    refute SolverResponse.bool_val(response, :y)
  end

  test "channeling sample problem with a tweak" do
    # Create the CP-SAT model.
    builder =
      Builder.new()
      |> Builder.def_int_var(:x, {0, 10})
      |> Builder.def_int_var(:y, {0, 10})
      |> Builder.def_bool_var(:b)
      |> Builder.constrain(:>=, :x, 5, if: :b)
      |> Builder.constrain(:<=, :x, 5, unless: :b)
      |> Builder.constrain(:==, LinearExpression.sum(:x, :y), 10, if: :b)
      |> Builder.constrain(:==, :y, 0, unless: :b)

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
    assert 2 == acc
  end
end
