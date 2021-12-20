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

  test "simple sat program" do
    model =
      Builder.new()
      |> Builder.def_int_var("x", {0, 2})
      |> Builder.def_int_var("y", {0, 2})
      |> Builder.def_int_var("z", {0, 2})
      |> Builder.constrain("x", :!=, "y")
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

  test "channeling sample problem with a tweak" do
    # Create the CP-SAT model.
    builder =
      Builder.new()
      |> Builder.def_int_var(:x, {0, 10})
      |> Builder.def_int_var(:y, {0, 10})
      |> Builder.def_bool_var(:b)
      |> Builder.constrain(:x, :>=, 5, if: :b)
      |> Builder.constrain(:x, :<, 5, unless: :b)
      |> Builder.constrain(LinearExpression.sum(:x, :y), :==, 10, if: :b)
      |> Builder.constrain(:y, :==, 0, unless: :b)

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
    assert 11 == acc
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

  test "minimal jobshop" do
    # task = (machine_id, processing_time).
    jobs_data = [
      # Job0
      [{0, 3}, {1, 2}, {2, 2}],
      # Job1
      [{0, 2}, {2, 1}, {1, 4}],
      # Job2
      [{1, 4}, {2, 3}]
    ]

    all_machines =
      jobs_data
      |> List.flatten()
      |> Enum.map(&elem(&1, 0))
      |> Enum.uniq()

    # Computes horizon dynamically as the sum of all durations.
    horizon =
      jobs_data
      |> List.flatten()
      |> Enum.map(&elem(&1, 1))
      |> Enum.sum()

    all_tasks = %{}
    machine_to_intervals = %{}

    acc = %{
      builder: Builder.new(),
      machine_to_intervals: machine_to_intervals,
      all_tasks: all_tasks
    }

    %{
      builder: builder,
      machine_to_intervals: machine_to_intervals,
      all_tasks: all_tasks
    } =
      jobs_data
      |> Enum.with_index()
      |> Enum.reduce(acc, fn {job, job_id}, acc ->
        job
        |> Enum.with_index()
        |> Enum.reduce(acc, fn {{machine_id, processing_time}, task_id},
                               %{
                                 builder: builder,
                                 machine_to_intervals: machine_to_intervals,
                                 all_tasks: all_tasks
                               } = acc ->
          suffix = "#{job_id}_#{task_id}"
          start_var = "start_#{suffix}"
          end_var = "end_#{suffix}"
          interval_var = "interval_#{suffix}"

          machine_to_intervals =
            Map.update(machine_to_intervals, machine_id, [interval_var], fn machine_intervals ->
              [interval_var | machine_intervals]
            end)

          all_tasks =
            Map.put(all_tasks, {job_id, task_id}, %{
              start: start_var,
              end: end_var,
              interval: interval_var
            })

          builder =
            builder
            |> Builder.def_int_var(start_var, {0, horizon})
            |> Builder.def_int_var(end_var, {0, horizon})
            |> Builder.def_interval_var(
              interval_var,
              start_var,
              processing_time,
              end_var
            )

          %{
            acc
            | builder: builder,
              machine_to_intervals: machine_to_intervals,
              all_tasks: all_tasks
          }
        end)
      end)

    builder =
      all_machines
      |> Enum.reduce(builder, fn machine, builder ->
        builder
        |> Builder.constrain(:no_overlap, machine_to_intervals[machine])
      end)

    builder =
      jobs_data
      |> Enum.with_index()
      |> Enum.reduce(builder, fn {job, job_id}, builder ->
        job
        |> Enum.slice(0, length(job) - 1)
        |> Enum.with_index()
        |> Enum.reduce(builder, fn {_job, task_id}, builder ->
          builder
          |> Builder.constrain(
            all_tasks[{job_id, task_id + 1}].start,
            :>=,
            all_tasks[{job_id, task_id}].end
          )
        end)
      end)

    builder =
      builder
      |> Builder.def_int_var("makespan", {0, horizon})
      |> Builder.max_equality(
        "makespan",
        jobs_data
        |> Enum.with_index()
        |> Enum.map(fn {job, job_id} ->
          all_tasks[{job_id, length(job) - 1}].end
        end)
      )
      |> Builder.minimize("makespan")

    assert :optimal ==
             builder
             |> Builder.build()
             |> Model.solve()
             |> then(& &1.status)
  end
end
