defmodule CpModelBuilderTest do
  use ExUnit.Case

  test "new int var" do
    model = CpModelBuilder.new()
    assert CpModelBuilder.def_int_var(model, "x", {0, 2})
  end

  test "new bool var" do
    model = CpModelBuilder.new()
    assert CpModelBuilder.def_bool_var(model, "x")
  end

  test "equal" do
    model =
      CpModelBuilder.new()
      |> CpModelBuilder.def_int_var("x", {0, 2})
      |> CpModelBuilder.def_int_var("y", {0, 2})

    assert CpModelBuilder.constrain(model, :==, "x", "y")
  end

  test "not equal" do
    model =
      CpModelBuilder.new()
      |> CpModelBuilder.def_int_var("x", {0, 2})
      |> CpModelBuilder.def_int_var("y", {0, 2})

    assert CpModelBuilder.constrain(model, :!=, :x, :y)
  end

  test "solve" do
    model =
      CpModelBuilder.new()
      |> CpModelBuilder.def_int_var("x", {0, 2})
      |> CpModelBuilder.def_int_var("y", {0, 2})
      |> CpModelBuilder.constrain(:!=, "x", "y")
      |> CpModelBuilder.build()

    assert %CpSolverResponse{} = Model.solve(model)
  end

  test "solution int value" do
    model =
      CpModelBuilder.new()
      |> CpModelBuilder.def_int_var("x", {0, 2})
      |> CpModelBuilder.def_int_var("y", {0, 2})
      |> CpModelBuilder.def_int_var("z", {0, 2})
      |> CpModelBuilder.constrain(:!=, "x", "y")
      |> CpModelBuilder.build()

    response = Model.solve(model)
    assert 1 == CpSolverResponse.int_val(response, "x")
  end

  test "simple sat program" do
    model =
      CpModelBuilder.new()
      |> CpModelBuilder.def_int_var("x", {0, 2})
      |> CpModelBuilder.def_int_var("y", {0, 2})
      |> CpModelBuilder.def_int_var("z", {0, 2})
      |> CpModelBuilder.constrain(:!=, "x", "y")
      |> CpModelBuilder.build()

    response = Model.solve(model)
    assert 1 == CpSolverResponse.int_val(response, "x")
    assert 0 == CpSolverResponse.int_val(response, "y")
    assert 0 == CpSolverResponse.int_val(response, "z")
  end

  test "simple sat program with DSL" do
    # Pure functions, pure Elixir
    builder =
      CpModelBuilder.new()
      |> CpModelBuilder.def_int_var(:x, {0, 2})
      |> CpModelBuilder.def_int_var(:y, {0, 2})
      |> CpModelBuilder.def_int_var(:z, {0, 2})
      |> CpModelBuilder.constrain(:!=, :x, :y)

    # Interacting with the underlying CP Model
    response =
      builder
      |> CpModelBuilder.build()
      |> Model.solve()

    assert 1 == CpSolverResponse.int_val(response, :x)
    assert 0 == CpSolverResponse.int_val(response, :y)
    assert 0 == CpSolverResponse.int_val(response, :z)
  end

  test "simple bool without DSL" do
    builder =
      CpModelBuilder.new()
      |> CpModelBuilder.def_bool_var("x")
      |> CpModelBuilder.def_bool_var("y")
      |> CpModelBuilder.constrain(:!=, "x", "y")

    # Interacting with the underlying CP Model
    response =
      builder
      |> CpModelBuilder.build()
      |> Model.solve()

    assert CpSolverResponse.bool_val(response, "x")
    refute CpSolverResponse.bool_val(response, "y")
  end

  test "simple bool DSL" do
    # Pure functions, pure Elixir
    builder =
      CpModelBuilder.new()
      |> CpModelBuilder.def_bool_var(:x)
      |> CpModelBuilder.def_bool_var(:y)
      |> CpModelBuilder.constrain(:!=, :x, :y)

    # Interacting with the underlying CP Model
    response =
      builder
      |> CpModelBuilder.build()
      |> Model.solve()

    assert CpSolverResponse.bool_val(response, :x)
    refute CpSolverResponse.bool_val(response, :y)
  end

  test "channeling sample problem with a tweak" do
    # Create the CP-SAT model.
    builder =
      CpModelBuilder.new()
      |> CpModelBuilder.def_int_var(:x, {0, 10})
      |> CpModelBuilder.def_int_var(:y, {0, 10})
      |> CpModelBuilder.def_bool_var(:b)
      |> CpModelBuilder.constrain(:>=, :x, 5, if: :b)
      |> CpModelBuilder.constrain(:<=, :x, 5, unless: :b)
      |> CpModelBuilder.constrain(:==, LinearExpression.sum(:x, :y), 10, if: :b)
      |> CpModelBuilder.constrain(:==, :y, 0, unless: :b)

    {response, acc} =
      builder
      |> CpModelBuilder.build()
      |> Model.solve(fn
        _response, nil -> 1
        _response, acc -> acc + 1
      end)

    assert response.status == :optimal
    assert 10 == CpSolverResponse.int_val(response, :x)
    assert 0 == CpSolverResponse.int_val(response, :y)
    assert CpSolverResponse.bool_val(response, :b)
    assert 2 == acc
  end
end
