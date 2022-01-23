defmodule Exhort.SAT.ExprTest do
  use ExUnit.Case
  use Exhort.SAT.Builder

  test "int less than" do
    v1 = Expr.def_int_var("v1", {1, 2})
    v2 = Expr.def_int_var("v2", {1, 2})
    c1 = Expr.new("v1" < "v2")
    c2 = Expr.new("v1" == 1)

    response =
      Builder.new()
      |> Builder.add(v1)
      |> Builder.add(v2)
      |> Builder.add(c1)
      |> Builder.add(c2)
      |> Builder.build()
      |> Model.solve()

    assert 1 == SolverResponse.value(response, v1)
    assert 2 == SolverResponse.value(response, v2)
  end

  test "int less than or equal to" do
    v1 = Expr.def_int_var("v1", {1, 2})
    v2 = Expr.def_int_var("v2", {1, 2})
    c1 = Expr.new("v1" <= "v2")
    c2 = Expr.new("v1" == 2)

    response =
      Builder.new()
      |> Builder.add(v1)
      |> Builder.add(v2)
      |> Builder.add(c1)
      |> Builder.add(c2)
      |> Builder.build()
      |> Model.solve()

    assert 2 == SolverResponse.value(response, v1)
    assert 2 == SolverResponse.value(response, v2)
  end

  test "int greater than or equal to" do
    v1 = Expr.def_int_var("v1", {1, 2})
    v2 = Expr.def_int_var("v2", {1, 2})
    c1 = Expr.new("v1" >= "v2")
    c2 = Expr.new("v1" == 1)

    response =
      Builder.new()
      |> Builder.add(v1)
      |> Builder.add(v2)
      |> Builder.add(c1)
      |> Builder.add(c2)
      |> Builder.build()
      |> Model.solve()

    assert 1 == SolverResponse.value(response, v1)
    assert 1 == SolverResponse.value(response, v2)
  end

  test "int greater than" do
    v1 = Expr.def_int_var("v1", {1, 2})
    v2 = Expr.def_int_var("v2", {1, 2})
    c1 = Expr.new("v1" > "v2")
    c2 = Expr.new("v1" == 2)

    response =
      Builder.new()
      |> Builder.add(v1)
      |> Builder.add(v2)
      |> Builder.add(c1)
      |> Builder.add(c2)
      |> Builder.build()
      |> Model.solve()

    assert 2 == SolverResponse.value(response, v1)
    assert 1 == SolverResponse.value(response, v2)
  end

  test "int equal" do
    v1 = Expr.def_int_var("v1", {0, 10})
    v2 = Expr.def_int_var("v2", {0, 10})
    c1 = Expr.new("v1" == "v2")
    c2 = Expr.new("v1" == 10)

    response =
      Builder.new()
      |> Builder.add(v1)
      |> Builder.add(v2)
      |> Builder.add(c1)
      |> Builder.add(c2)
      |> Builder.build()
      |> Model.solve()

    assert 10 == SolverResponse.value(response, v1)
    assert 10 == SolverResponse.value(response, v2)
  end

  test "bool equal" do
    v1 = Expr.def_bool_var("v1")
    v2 = Expr.def_bool_var("v2")
    c1 = Expr.new("v1" == "v2")
    c2 = Expr.new("v1" == 1)

    response =
      Builder.new()
      |> Builder.add(v1)
      |> Builder.add(v2)
      |> Builder.add(c1)
      |> Builder.add(c2)
      |> Builder.build()
      |> Model.solve()

    assert SolverResponse.value(response, v1)
    assert SolverResponse.value(response, v2)
  end

  test "not" do
    v1 = Expr.def_bool_var("v1")
    v2 = Expr.def_bool_var("v2")
    c1 = Expr.new("v1" == not "v2")
    c2 = Expr.new("v1" == 0)

    response =
      Builder.new()
      |> Builder.add(v1)
      |> Builder.add(v2)
      |> Builder.add(c1)
      |> Builder.add(c2)
      |> Builder.build()
      |> Model.solve()

    refute SolverResponse.value(response, v1)
    assert SolverResponse.value(response, v2)
  end

  test "bool_and" do
    v1 = Expr.def_bool_var("v1")
    v2 = Expr.def_bool_var("v2")
    c1 = Expr.bool_and(["v1", "v2"])

    response =
      Builder.new()
      |> Builder.add(v1)
      |> Builder.add(v2)
      |> Builder.add(c1)
      |> Builder.build()
      |> Model.solve()

    assert SolverResponse.value(response, v1)
    assert SolverResponse.value(response, v2)
  end

  test "bool_or" do
    v1 = Expr.def_bool_var("v1")
    v2 = Expr.def_bool_var("v2")
    c1 = Expr.bool_or(["v1", "v2"])
    c2 = Expr.new("v1" == 0)

    response =
      Builder.new()
      |> Builder.add(v1)
      |> Builder.add(v2)
      |> Builder.add(c1)
      |> Builder.add(c2)
      |> Builder.build()
      |> Model.solve()

    refute SolverResponse.value(response, v1)
    assert SolverResponse.value(response, v2)
  end

  test "implication" do
    v1 = Expr.def_bool_var("v1")
    v2 = Expr.def_bool_var("v2")
    c1 = Expr.implication(not "v1", "v2")
    c2 = Expr.new("v1" == 1)

    response =
      Builder.new()
      |> Builder.add(v1)
      |> Builder.add(v2)
      |> Builder.add(c1)
      |> Builder.add(c2)
      |> Builder.build()
      |> Model.solve()

    assert SolverResponse.value(response, v1)
    refute SolverResponse.value(response, v2)
  end

  test "all_different" do
    v1 = Expr.def_int_var("v1", {1, 2})
    v2 = Expr.def_int_var("v2", {1, 2})
    c1 = Expr.new("v1" == 1)
    c2 = Expr.all_different(["v1", "v2"])

    response =
      Builder.new()
      |> Builder.add(v1)
      |> Builder.add(v2)
      |> Builder.add(c1)
      |> Builder.add(c2)
      |> Builder.build()
      |> Model.solve()

    assert 1 == SolverResponse.value(response, v1)
    assert 2 == SolverResponse.value(response, v2)
  end
end
