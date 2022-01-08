defmodule Samples.Exhort.SAT.MinimalJobShop do
  use ExUnit.Case
  use Exhort.SAT.Builder

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
            |> Builder.def_int_var(^start_var, {0, horizon})
            |> Builder.def_int_var(^end_var, {0, horizon})
            |> Builder.def_interval_var(
              ^interval_var,
              ^start_var,
              ^processing_time,
              ^end_var
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
        |> Builder.constrain_list(:no_overlap, machine_to_intervals[machine])
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

    response =
      builder
      |> Builder.build()
      |> Model.solve()

    assert :optimal == response.status
    assert 11.0 == response.objective

    assert %{
             "Machine: 0" => %{"0_0" => {2, 5}, "1_0" => {0, 2}},
             "Machine: 1" => %{"0_1" => {5, 7}, "1_2" => {7, 11}, "2_0" => {0, 4}},
             "Machine: 2" => %{"0_2" => {7, 9}, "1_1" => {2, 3}, "2_1" => {4, 7}}
           } =
             jobs_data
             |> Enum.with_index()
             |> Enum.map(fn {job, job_id} ->
               job
               |> Enum.with_index()
               |> Enum.map(fn {{machine_id, _processing_time}, task_id} ->
                 suffix = "#{job_id}_#{task_id}"
                 start_var = "start_#{suffix}"
                 end_var = "end_#{suffix}"

                 {
                   "Machine: #{machine_id}",
                   {suffix, SolverResponse.int_val(response, ^start_var),
                    SolverResponse.int_val(response, ^end_var)}
                 }
               end)
             end)
             |> List.flatten()
             |> Enum.group_by(fn {machine, _} -> machine end)
             |> Enum.map(fn {machine, jobs} ->
               {
                 machine,
                 jobs
                 |> Enum.map(fn {_machine, {id, task_start, task_end}} ->
                   {id, {task_start, task_end}}
                 end)
                 |> Enum.into(%{})
               }
             end)
             |> Enum.into(%{})
  end
end
