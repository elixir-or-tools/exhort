defmodule CpModelBuilderTest do
  use ExUnit.Case

  test "builder" do
    assert CpModelBuilder.new()
  end

  test "new int var" do
    {:ok, cp_model_builder} = CpModelBuilder.new()
    assert CpModelBuilder.new_int_var(cp_model_builder, 0, 2, "x")
  end

  test "new bool var" do
    {:ok, cp_model_builder} = CpModelBuilder.new()
    assert CpModelBuilder.new_bool_var(cp_model_builder, "x")
  end

  test "equal" do
    {:ok, cp_model_builder} = CpModelBuilder.new()

    x = CpModelBuilder.new_int_var(cp_model_builder, 0, 2, "x")
    y = CpModelBuilder.new_int_var(cp_model_builder, 0, 2, "y")

    assert CpModelBuilder.add_equal(cp_model_builder, x, y)
  end

  test "not equal" do
    {:ok, cp_model_builder} = CpModelBuilder.new()

    x = CpModelBuilder.new_int_var(cp_model_builder, 0, 2, "x")
    y = CpModelBuilder.new_int_var(cp_model_builder, 0, 2, "y")
    assert CpModelBuilder.add_not_equal(cp_model_builder, x, y)
  end

  test "solve" do
    {:ok, cp_model_builder} = CpModelBuilder.new()

    x = CpModelBuilder.new_int_var(cp_model_builder, 0, 2, "x")
    y = CpModelBuilder.new_int_var(cp_model_builder, 0, 2, "y")
    CpModelBuilder.add_not_equal(cp_model_builder, x, y)
    assert CpModelBuilder.solve(cp_model_builder)
  end

  test "solution int value" do
    {:ok, cp_model_builder} = CpModelBuilder.new()

    x = CpModelBuilder.new_int_var(cp_model_builder, 0, 2, "x")
    y = CpModelBuilder.new_int_var(cp_model_builder, 0, 2, "y")
    _z = CpModelBuilder.new_int_var(cp_model_builder, 0, 2, "z")
    CpModelBuilder.add_not_equal(cp_model_builder, x, y)
    response = CpModelBuilder.solve(cp_model_builder)
    assert 1 == CpModelBuilder.solution_integer_value(response, x)
  end

  test "simple sat program" do
    {:ok, cp_model_builder} = CpModelBuilder.new()

    x = CpModelBuilder.new_int_var(cp_model_builder, 0, 2, "x")
    y = CpModelBuilder.new_int_var(cp_model_builder, 0, 2, "y")
    z = CpModelBuilder.new_int_var(cp_model_builder, 0, 2, "z")
    CpModelBuilder.add_not_equal(cp_model_builder, x, y)
    response = CpModelBuilder.solve(cp_model_builder)
    assert 1 == CpModelBuilder.solution_integer_value(response, x)
    assert 0 == CpModelBuilder.solution_integer_value(response, y)
    assert 0 == CpModelBuilder.solution_integer_value(response, z)
  end

  test "simple sat program with DSL" do
    # Pure functions, pure Elixir
    builder =
      CpModelBuilder.new_builder()
      |> CpModelBuilder.def_int_var(:x, {0, 2})
      |> CpModelBuilder.def_int_var(:y, {0, 2})
      |> CpModelBuilder.def_int_var(:z, {0, 2})
      |> CpModelBuilder.require(:!=, :x, :y)

    # Interacting with the underlying CP Model
    response =
      builder
      |> CpModelBuilder.build()
      |> CpModelBuilder.solve()

    assert 1 == CpModelBuilder.int_val(response, :x)
    assert 0 == CpModelBuilder.int_val(response, :y)
    assert 0 == CpModelBuilder.int_val(response, :z)
  end

  test "simple bool DSL" do
    # Pure functions, pure Elixir
    builder =
      CpModelBuilder.new_builder()
      |> CpModelBuilder.def_bool_var(:x)
      |> CpModelBuilder.def_bool_var(:y)
      |> CpModelBuilder.require(:!=, :x, :y)

    # Interacting with the underlying CP Model
    response =
      builder
      |> CpModelBuilder.build()
      |> CpModelBuilder.solve()

    assert CpModelBuilder.bool_val(response, :x)
    refute CpModelBuilder.bool_val(response, :y)
  end

  test "channeling sample problem with a tweak" do
    # Create the CP-SAT model.
    builder =
      CpModelBuilder.new_builder()
      |> CpModelBuilder.def_int_var(:x, {0, 10})
      |> CpModelBuilder.def_int_var(:y, {0, 10})
      |> CpModelBuilder.def_bool_var(:b)
      |> CpModelBuilder.require(:>=, :x, 5, if: :b)
      |> CpModelBuilder.require(:<=, :x, 5, unless: :b)
      |> CpModelBuilder.require(:==, LinearExpression.sum(:x, :y), 10, if: :b)
      |> CpModelBuilder.require(:==, :y, 0, unless: :b)

    response =
      builder
      |> CpModelBuilder.build()
      |> CpModelBuilder.solve()

    assert 10 == CpModelBuilder.int_val(response, :x)
    assert 0 == CpModelBuilder.int_val(response, :y)
    assert false == CpModelBuilder.bool_val(response, :b)
  end
end
