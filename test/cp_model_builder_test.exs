defmodule CpModelBuilderTest do
  use ExUnit.Case

  test "new int var" do
    builder = CpModelBuilder.new()
    assert CpModelBuilder.def_int_var(builder, "x", {0, 2})
  end

  test "new bool var" do
    builder = CpModelBuilder.new()
    assert CpModelBuilder.def_bool_var(builder, "x")
  end

  test "equal" do
    builder =
      CpModelBuilder.new()
      |> CpModelBuilder.def_int_var("x", {0, 2})
      |> CpModelBuilder.def_int_var("y", {0, 2})

    assert CpModelBuilder.constrain(builder, :==, "x", "y")
  end

  test "not equal" do
    builder =
      CpModelBuilder.new()
      |> CpModelBuilder.def_int_var("x", {0, 2})
      |> CpModelBuilder.def_int_var("y", {0, 2})

    assert CpModelBuilder.constrain(builder, :!=, :x, :y)
  end

  test "solve" do
    builder =
      CpModelBuilder.new()
      |> CpModelBuilder.def_int_var("x", {0, 2})
      |> CpModelBuilder.def_int_var("y", {0, 2})
      |> CpModelBuilder.constrain(:!=, "x", "y")
      |> CpModelBuilder.build()

    assert %CpSolverResponse{} = CpModelBuilder.solve(builder)
  end

  test "solution int value" do
    builder =
      CpModelBuilder.new()
      |> CpModelBuilder.def_int_var("x", {0, 2})
      |> CpModelBuilder.def_int_var("y", {0, 2})
      |> CpModelBuilder.def_int_var("z", {0, 2})
      |> CpModelBuilder.constrain(:!=, "x", "y")
      |> CpModelBuilder.build()

    response = CpModelBuilder.solve(builder)
    assert 1 == CpSolverResponse.int_val(response, "x")
  end

  test "simple sat program" do
    builder =
      CpModelBuilder.new()
      |> CpModelBuilder.def_int_var("x", {0, 2})
      |> CpModelBuilder.def_int_var("y", {0, 2})
      |> CpModelBuilder.def_int_var("z", {0, 2})
      |> CpModelBuilder.constrain(:!=, "x", "y")
      |> CpModelBuilder.build()

    response = CpModelBuilder.solve(builder)
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
      |> CpModelBuilder.solve()

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
      |> CpModelBuilder.solve()

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
      |> CpModelBuilder.solve()

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

    response =
      builder
      |> CpModelBuilder.build()
      |> CpModelBuilder.solve()

    assert response.status == :optimal
    assert 10 == CpSolverResponse.int_val(response, :x)
    assert 0 == CpSolverResponse.int_val(response, :y)
    assert false == CpSolverResponse.bool_val(response, :b)
  end
end
