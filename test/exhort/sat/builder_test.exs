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

  test "zebra" do
    builder =
      Builder.new()
      |> Builder.def_int_var("red", {1, 5})
      |> Builder.def_int_var("green", {1, 5})
      |> Builder.def_int_var("yellow", {1, 5})
      |> Builder.def_int_var("blue", {1, 5})
      |> Builder.def_int_var("ivory", {1, 5})
      |> Builder.def_int_var("englishman", {1, 5})
      |> Builder.def_int_var("spaniard", {1, 5})
      |> Builder.def_int_var("japanese", {1, 5})
      |> Builder.def_int_var("ukrainian", {1, 5})
      |> Builder.def_int_var("norwegian", {1, 5})
      |> Builder.def_int_var("dog", {1, 5})
      |> Builder.def_int_var("snails", {1, 5})
      |> Builder.def_int_var("fox", {1, 5})
      |> Builder.def_int_var("zebra", {1, 5})
      |> Builder.def_int_var("horse", {1, 5})
      |> Builder.def_int_var("tea", {1, 5})
      |> Builder.def_int_var("coffee", {1, 5})
      |> Builder.def_int_var("water", {1, 5})
      |> Builder.def_int_var("milk", {1, 5})
      |> Builder.def_int_var("fruit juice", {1, 5})
      |> Builder.def_int_var("old gold", {1, 5})
      |> Builder.def_int_var("kools", {1, 5})
      |> Builder.def_int_var("chesterfields", {1, 5})
      |> Builder.def_int_var("lucky strike", {1, 5})
      |> Builder.def_int_var("parliaments", {1, 5})
      |> Builder.constrain(:"all!=", ["red", "green", "yellow", "blue", "ivory"])
      |> Builder.constrain(:"all!=", [
        "englishman",
        "spaniard",
        "japanese",
        "ukrainian",
        "norwegian"
      ])
      |> Builder.constrain(:"all!=", ["dog", "snails", "fox", "zebra", "horse"])
      |> Builder.constrain(:"all!=", ["tea", "coffee", "water", "milk", "fruit juice"])
      |> Builder.constrain(:"all!=", [
        "parliaments",
        "kools",
        "chesterfields",
        "lucky strike",
        "old gold"
      ])
      |> Builder.constrain(:==, "englishman", "red")
      |> Builder.constrain(:==, "spaniard", "dog")
      |> Builder.constrain(:==, "coffee", "green")
      |> Builder.constrain(:==, "ukrainian", "tea")
      |> Builder.constrain(:==, "green", LinearExpression.sum("ivory", 1))
      |> Builder.constrain(:==, "old gold", "snails")
      |> Builder.constrain(:==, "kools", "yellow")
      |> Builder.constrain(:==, "milk", 3)
      |> Builder.constrain(:==, "norwegian", 1)
      |> Builder.def_int_var("diff_fox_chesterfields", {-4, 4})
      |> Builder.constrain(
        :==,
        "diff_fox_chesterfields",
        LinearExpression.minus("fox", "chesterfields")
      )
      |> Builder.constrain(:"abs==", "diff_fox_chesterfields", 1)
      |> Builder.def_int_var("diff_horse_kools", {-4, 4})
      |> Builder.constrain(
        :==,
        "diff_horse_kools",
        LinearExpression.minus("horse", "kools")
      )
      |> Builder.constrain(:"abs==", "diff_horse_kools", 1)
      |> Builder.constrain(:==, "lucky strike", "fruit juice")
      |> Builder.constrain(:==, "japanese", "parliaments")
      |> Builder.def_int_var("diff_norwegian_blue", {-4, 4})
      |> Builder.constrain(
        :==,
        "diff_norwegian_blue",
        LinearExpression.minus("norwegian", "blue")
      )

    # This causes an infeasible result
    # |> Builder.constrain(:"abs==", "diff_norwegian_blue", 1)

    # Solve and print out the solution.
    response =
      builder
      |> Builder.build()
      |> Model.solve()

    assert response.status == :optimal

    if response.status == :optimal do
      people = ["englishman", "spaniard", "japanese", "ukrainian", "norwegian"]

      assert Enum.find(people, fn p ->
               SolverResponse.int_val(response, p) == SolverResponse.int_val(response, "water")
             end)

      assert Enum.find(people, fn p ->
               SolverResponse.int_val(response, p) == SolverResponse.int_val(response, "zebra")
             end)
    end
  end
end
