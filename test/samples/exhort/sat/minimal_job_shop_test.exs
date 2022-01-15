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

    # Computes horizon dynamically as the sum of all durations.
    horizon =
      jobs_data
      |> List.flatten()
      |> Enum.map(&elem(&1, 1))
      |> Enum.sum()

    # [
    #   {0, [{0, {0, 3}}, {1, {1, 2}}, {2, {2, 2}}]},
    #   {1, [{0, {0, 2}}, {1, {2, 1}}, {2, {1, 4}}]},
    #   {2, [{0, {1, 4}}, {1, {2, 3}}]}
    # ]
    jobs =
      jobs_data
      |> Enum.with_index()
      |> Enum.map(fn {job, job_id} ->
        {
          job_id,
          job
          |> Enum.with_index()
          |> Enum.map(fn {{machine_id, processing_time}, task_id} ->
            {task_id, {machine_id, processing_time}}
          end)
        }
      end)

    # %{{job_id, task_id} => %{machine: _, start: _, processing_time: _, end: _, interval: _}}
    tasks =
      jobs
      |> Enum.map(fn {job_id, job} ->
        job
        |> Enum.map(fn {task_id, {machine_id, processing_time}} ->
          suffix = "#{job_id}_#{task_id}"

          {
            {job_id, task_id},
            %{
              machine: machine_id,
              start: "start_#{suffix}",
              processing_time: processing_time,
              end: "end_#{suffix}",
              interval: "interval_#{suffix}"
            }
          }
        end)
      end)
      |> List.flatten()
      |> Enum.into(%{})

    machine_constraints =
      tasks
      |> Enum.map(fn {_, %{machine: machine_id, interval: interval_var}} ->
        {machine_id, interval_var}
      end)
      |> Enum.group_by(fn {machine_id, _} -> machine_id end, fn {_, interval_var} ->
        interval_var
      end)
      |> Enum.map(fn {_machine_id, intervals} ->
        Constraint.no_overlap(intervals)
      end)

    task_vars =
      tasks
      |> Map.values()
      |> Enum.map(fn
        %{
          start: start_var,
          processing_time: processing_time,
          end: end_var,
          interval: interval_var
        } ->
          [
            IntVar.new(start_var, {0, horizon}),
            IntVar.new(end_var, {0, horizon}),
            IntervalVar.new(interval_var, start_var, processing_time, end_var)
          ]
      end)
      |> List.flatten()

    task_constraints =
      jobs
      |> Enum.map(fn {job_id, job} ->
        job
        |> Enum.slice(0, length(job) - 1)
        |> Enum.map(fn {task_id, _task} ->
          task_start = tasks[{job_id, task_id + 1}].start
          task_end = tasks[{job_id, task_id}].end
          Constraint.new(^task_start >= ^task_end)
        end)
      end)
      |> List.flatten()

    builder =
      Builder.new()
      |> Builder.add(task_vars)
      |> Builder.add(machine_constraints)
      |> Builder.add(task_constraints)
      |> Builder.def_int_var("makespan", {0, horizon})
      |> Builder.max_equality(
        "makespan",
        jobs
        |> Enum.map(fn {job_id, job} ->
          tasks[{job_id, length(job) - 1}].end
        end)
      )
      |> Builder.minimize("makespan")

    response =
      builder
      |> Builder.build()
      |> Model.solve()

    assert :optimal == response.status
    assert 11 == response.objective

    assert %{
             "Machine: 0" => %{"0_0" => {2, 5}, "1_0" => {0, 2}},
             "Machine: 1" => %{"0_1" => {5, 7}, "1_2" => {7, 11}, "2_0" => {0, 4}},
             "Machine: 2" => %{"0_2" => {7, 9}, "1_1" => {2, 3}, "2_1" => {4, 7}}
           } =
             tasks
             |> Enum.map(fn {{job_id, task_id},
                             %{machine: machine_id, start: start_var, end: end_var}} ->
               {
                 "Machine: #{machine_id}",
                 {
                   "#{job_id}_#{task_id}",
                   SolverResponse.int_val(response, ^start_var),
                   SolverResponse.int_val(response, ^end_var)
                 }
               }
             end)
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
