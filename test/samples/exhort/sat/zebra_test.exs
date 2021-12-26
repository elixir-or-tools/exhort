defmodule Samples.Exhort.SAT.Zebra do
  use ExUnit.Case

  alias Exhort.SAT.Builder
  alias Exhort.SAT.LinearExpression
  alias Exhort.SAT.SolverResponse
  alias Exhort.SAT.Model

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
      |> Builder.constrain_list(:"all!=", ["red", "green", "yellow", "blue", "ivory"])
      |> Builder.constrain_list(:"all!=", [
        "englishman",
        "spaniard",
        "japanese",
        "ukrainian",
        "norwegian"
      ])
      |> Builder.constrain_list(:"all!=", ["dog", "snails", "fox", "zebra", "horse"])
      |> Builder.constrain_list(:"all!=", ["tea", "coffee", "water", "milk", "fruit juice"])
      |> Builder.constrain_list(:"all!=", [
        "parliaments",
        "kools",
        "chesterfields",
        "lucky strike",
        "old gold"
      ])
      |> Builder.constrain("englishman", :==, "red")
      |> Builder.constrain("spaniard", :==, "dog")
      |> Builder.constrain("coffee", :==, "green")
      |> Builder.constrain("ukrainian", :==, "tea")
      |> Builder.constrain("green", :==, LinearExpression.sum("ivory", 1))
      |> Builder.constrain("old gold", :==, "snails")
      |> Builder.constrain("kools", :==, "yellow")
      |> Builder.constrain("milk", :==, 3)
      |> Builder.constrain("norwegian", :==, 1)
      |> Builder.def_int_var("diff_fox_chesterfields", {-4, 4})
      |> Builder.constrain(
        "diff_fox_chesterfields",
        :==,
        LinearExpression.minus("fox", "chesterfields")
      )
      |> Builder.constrain(1, :"abs==", "diff_fox_chesterfields")
      |> Builder.def_int_var("diff_horse_kools", {-4, 4})
      |> Builder.constrain(
        "diff_horse_kools",
        :==,
        LinearExpression.minus("horse", "kools")
      )
      |> Builder.constrain(1, :"abs==", "diff_horse_kools")
      |> Builder.constrain("lucky strike", :==, "fruit juice")
      |> Builder.constrain("japanese", :==, "parliaments")
      |> Builder.def_int_var("diff_norwegian_blue", {-4, 4})
      |> Builder.constrain(
        "diff_norwegian_blue",
        :==,
        LinearExpression.minus("norwegian", "blue")
      )
      |> Builder.constrain(1, :"abs==", "diff_norwegian_blue")

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
