defmodule Samples.Exhort.SAT.RankingSampleTest do
  use ExUnit.Case
  use Exhort.SAT.Builder

  test "ranking sample" do
    # Ranks tasks in a `no_overlap` constraint.

    horizon = 100
    num_tasks = 4
    all_tasks = 0..3

    %{
      starts: starts,
      ends: ends,
      presences: presences,
      presence_expr: presences_expr,
      o_intervals: o_intervals,
      ranks: ranks
    } =
      for task <- all_tasks do
        duration = task + 1
        presence = task < div(num_tasks, 2)

        %{
          starts: {task, Expr.def_int_var("starts_#{task}", {0, horizon})},
          ends: {task, Expr.def_int_var("ends_#{task}", {0, horizon})},
          presences: {task, Expr.def_bool_var("presence_#{task}")},
          presence_expr: {task, if(presence, do: Expr.new("presence_#{task}" == 1))},
          o_intervals:
            {task,
             Expr.def_interval_var(
               "o_interval_#{task}",
               "starts_#{task}",
               duration,
               "ends_#{task}",
               if: "presence_#{task}"
             )},
          ranks: {task, Expr.def_int_var("ranks_#{task}", {-1, num_tasks - 1})}
        }
      end
      |> Enum.reduce(%{}, fn task_vars, merged ->
        Map.merge(merged, task_vars, fn
          _, merged_var, {_, nil} ->
            merged_var

          _, merged_var, new_var when is_list(merged_var) ->
            [new_var | merged_var]

          _, merged_var, new_var ->
            [new_var, merged_var]
        end)
      end)
      |> Enum.map(fn {key, task_vars} ->
        {key, Enum.into(task_vars, %{})}
      end)
      |> Enum.into(%{})

    no_overlap_intervals = Expr.no_overlap(for task <- all_tasks, do: o_intervals[task])

    # Add constraints and variables to links tasks and ranks.

    # Assumes that all starts are disjoint, meaning that all tasks have a
    # strictly positive duration, and they appear in the same `:no_overlap`
    # constraint.

    # Precedence variables

    # Creates precedence variables between pairs of intervals.

    presedence_defs =
      for i <- all_tasks, j <- all_tasks do
        if i == j do
          {{i, j}, presences[i]}
        else
          i_before_j = "#{i} before #{j}"

          {
            Expr.def_bool_var(i_before_j),
            Expr.new(starts[i] < starts[j], if: i_before_j),
            {{i, j}, i_before_j}
          }
        end
      end

    precedences =
      presedence_defs
      |> Enum.map(fn
        {_, _, ij} -> ij
        ij -> ij
      end)
      |> Enum.into(%{})

    precedence_constraints =
      presedence_defs
      |> Enum.filter(fn
        {_, _} -> false
        {_, _, _} -> true
      end)
      |> Enum.map(fn {bool, const, _} -> [bool, const] end)
      |> List.flatten()

    # Optional intervals

    optional_intervals =
      for i <- Enum.take(all_tasks, Range.size(all_tasks) - 1),
          j <- Range.new(i + 1, num_tasks - 1) do
        [
          Expr.implication(not presences[i], not precedences[{i, j}]),
          Expr.implication(not presences[i], not precedences[{j, i}]),
          Expr.implication(not presences[j], not precedences[{i, j}]),
          Expr.bool_or([
            precedences[{i, j}],
            precedences[{j, i}],
            not presences[i],
            not presences[j]
          ]),
          Expr.implication(precedences[{i, j}], not precedences[{j, i}]),
          Expr.implication(precedences[{j, i}], not precedences[{i, j}])
        ]
      end
      |> List.flatten()

    # Links precedences and ranks

    precedences_to_ranks =
      for i <- all_tasks do
        Expr.new(ranks[i] == sum(for j <- all_tasks, do: precedences[{j, i}]) - 1)
      end

    rank_0 = Expr.new(ranks[0] < ranks[1])
    makespan = Expr.def_int_var("makespan", {0, horizon})

    makespan_constraints =
      for task <- all_tasks do
        Expr.new(ends[task] <= makespan, if: presences[task])
      end

    # Solve the model.

    response =
      Builder.new()
      |> Builder.add(Map.values(starts))
      |> Builder.add(Map.values(ends))
      |> Builder.add(Map.values(presences))
      |> Builder.add(Map.values(presences_expr))
      |> Builder.add(Map.values(o_intervals))
      |> Builder.add(Map.values(ranks))
      |> Builder.add(no_overlap_intervals)
      |> Builder.add(precedence_constraints)
      |> Builder.add(optional_intervals)
      |> Builder.add(precedences_to_ranks)
      |> Builder.add(rank_0)
      |> Builder.add(makespan)
      |> Builder.add(makespan_constraints)
      |> Builder.minimize(2 * makespan - 7 * sum(for task <- all_tasks, do: presences[task]))
      |> Builder.build()
      |> Model.solve()

    assert %{objective: -9.0, status: :optimal} = SolverResponse.stats(response)

    assert 6 == SolverResponse.value(response, makespan)

    task_results =
      for task <- all_tasks do
        if SolverResponse.value(response, presences[task]) do
          {
            SolverResponse.value(response, starts[task]),
            SolverResponse.value(response, ranks[task])
          }
        else
          SolverResponse.value(response, ranks[task])
        end
      end

    assert [{0, 0}, {1, 1}, {3, 2}, -1] == task_results
  end
end
