defmodule Samples.Exhort.SAT.NoOverlap do
  use ExUnit.Case
  use Exhort.SAT.Builder

  test "no overlap" do
    horizon = 21

    response =
      Builder.new()
      # Task 0, duration 2
      |> Builder.def_int_var("start_0", {0, horizon})
      |> Builder.def_constant("duration_0", 2)
      |> Builder.def_int_var("end_0", {0, horizon})
      |> Builder.def_interval_var("task_0", "start_0", "duration_0", "end_0")
      # Task 1, duration 4
      |> Builder.def_int_var("start_1", {0, horizon})
      |> Builder.def_constant("duration_1", 4)
      |> Builder.def_int_var("end_1", {0, horizon})
      |> Builder.def_interval_var("task_1", "start_1", "duration_1", "end_1")
      # Task 2, duration 3
      |> Builder.def_int_var("start_2", {0, horizon})
      |> Builder.def_constant("duration_2", 3)
      |> Builder.def_int_var("end_2", {0, horizon})
      |> Builder.def_interval_var("task_2", "start_2", "duration_2", "end_2")
      # Weekends
      |> Builder.def_constant("5", 5)
      |> Builder.def_constant("2", 2)
      |> Builder.def_constant("7", 7)
      |> Builder.def_interval_var("weekend_0", "5", "2", "7")
      |> Builder.def_constant("12", 12)
      |> Builder.def_constant("14", 14)
      |> Builder.def_interval_var("weekend_1", "12", "2", "14")
      |> Builder.def_constant("19", 19)
      |> Builder.def_constant("21", 21)
      |> Builder.def_interval_var("weekend_2", "19", "2", "21")
      |> Builder.constrain_list(:no_overlap, [
        "task_0",
        "task_1",
        "task_2",
        "weekend_0",
        "weekend_1",
        "weekend_2"
      ])
      |> Builder.def_int_var("makespan", {0, horizon})
      |> Builder.constrain("end_0", :<=, "makespan")
      |> Builder.constrain("end_1", :<=, "makespan")
      |> Builder.constrain("end_2", :<=, "makespan")
      |> Builder.minimize("makespan")
      |> Builder.build()
      |> Model.solve()

    assert :optimal == response.status
  end
end
