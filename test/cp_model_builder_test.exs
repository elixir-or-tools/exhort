defmodule CpModelBuilderTest do
  use ExUnit.Case

  test "concatenates a string" do
    assert "Saying: hi" == CpModelBuilder.print("hi")
  end

  test "builder" do
    assert CpModelBuilder.new()
  end

  test "new int var" do
    {:ok, cp_model_builder} = CpModelBuilder.new()
    assert CpModelBuilder.new_int_var(cp_model_builder, 0, 2, "x")
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
end
