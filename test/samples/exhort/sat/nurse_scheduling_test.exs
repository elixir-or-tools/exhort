defmodule Samples.Exhort.SAT.NurseScheduling do
  use ExUnit.Case
  use Exhort.SAT.Builder

  test "nurse scheduling" do
    num_nurses = 5
    num_shifts = 3
    num_days = 7
    all_nurses = 1..num_nurses
    all_shifts = 1..num_shifts
    all_days = 1..num_days

    shift_requests = [
      [[0, 0, 1], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 1], [0, 1, 0], [0, 0, 1]],
      [[0, 0, 0], [0, 0, 0], [0, 1, 0], [0, 1, 0], [1, 0, 0], [0, 0, 0], [0, 0, 1]],
      [[0, 1, 0], [0, 1, 0], [0, 0, 0], [1, 0, 0], [0, 0, 0], [0, 1, 0], [0, 0, 0]],
      [[0, 0, 1], [0, 0, 0], [1, 0, 0], [0, 1, 0], [0, 0, 0], [1, 0, 0], [0, 0, 0]],
      [[0, 0, 0], [0, 0, 1], [0, 1, 0], [0, 0, 0], [1, 0, 0], [0, 1, 0], [0, 0, 0]]
    ]

    shifts =
      Enum.map(all_nurses, fn nurse ->
        Enum.map(all_days, fn day ->
          Enum.map(all_shifts, fn shift ->
            {nurse, day, shift}
          end)
        end)
      end)
      |> List.flatten()

    shift_vars =
      shifts
      |> Enum.map(fn {nurse, day, shift} ->
        Expr.def_bool_var("shift_#{nurse}_#{day}_#{shift}")
      end)

    # Each shift is assigned to exactly one nurse in the schedule period.
    shift_nurses_per_period =
      all_days
      |> Enum.map(fn day ->
        all_shifts
        |> Enum.map(fn shift ->
          shift_options = Enum.filter(shifts, fn {_n, d, s} -> d == day and s == shift end)
          shift_option_vars = Enum.map(shift_options, fn {n, d, s} -> "shift_#{n}_#{d}_#{s}" end)

          Expr.new(sum(shift_option_vars) == 1)
        end)
      end)
      |> List.flatten()

    # Each nurse works at most one shift per day
    nurse_shifts_per_day =
      all_nurses
      |> Enum.map(fn nurse ->
        all_days
        |> Enum.map(fn day ->
          shift_options = Enum.filter(shifts, fn {n, d, _s} -> n == nurse and d == day end)
          shift_option_vars = Enum.map(shift_options, fn {n, d, s} -> "shift_#{n}_#{d}_#{s}" end)

          Expr.new(sum(shift_option_vars) <= 1)
        end)
      end)
      |> List.flatten()

    # Try to distribute the shifts evenly, so that each nurse works
    # min_shifts_per_nurse shifts. If this is not possible, because the total
    # number of shifts is not divisible by the number of nurses, some nurses
    # will be assigned one more shift.

    min_shifts_per_nurse = div(num_shifts * num_days, num_nurses)

    max_shifts_per_nurse =
      if rem(num_shifts * num_days, num_nurses) == 0 do
        min_shifts_per_nurse
      else
        min_shifts_per_nurse + 1
      end

    distribution_constraints =
      all_nurses
      |> Enum.map(fn nurse ->
        shift_options = Enum.filter(shifts, fn {n, _d, _s} -> n == nurse end)
        shift_option_vars = Enum.map(shift_options, fn {n, d, s} -> "shift_#{n}_#{d}_#{s}" end)

        [
          Expr.new(min_shifts_per_nurse <= sum(shift_option_vars)),
          Expr.new(sum(shift_option_vars) <= max_shifts_per_nurse)
        ]
      end)
      |> List.flatten()

    # Objective function
    max_list =
      all_nurses
      |> Enum.map(fn nurse ->
        all_days
        |> Enum.map(fn day ->
          all_shifts
          |> Enum.map(fn shift ->
            shift_var = "shift_#{nurse}_#{day}_#{shift}"

            request =
              shift_requests |> Enum.at(nurse - 1) |> Enum.at(day - 1) |> Enum.at(shift - 1)

            Expr.new(shift_var * request)
          end)
        end)
      end)
      |> List.flatten()

    response =
      Builder.new()
      |> Builder.add(shift_vars)
      |> Builder.add(shift_nurses_per_period)
      |> Builder.add(nurse_shifts_per_day)
      |> Builder.add(distribution_constraints)
      |> Builder.maximize(sum(max_list))
      |> Builder.build()
      |> Model.solve()

    assert response.status == :optimal
    assert response.objective == 13

    shift_counts =
      Enum.reduce(all_nurses, [], fn nurse, acc ->
        count =
          Enum.reduce(all_days, 0, fn day, acc ->
            Enum.reduce(all_shifts, acc, fn shift, acc ->
              if SolverResponse.bool_val(response, "shift_#{nurse}_#{day}_#{shift}") do
                acc + 1
              else
                acc
              end
            end)
          end)

        acc ++ [count]
      end)

    assert shift_counts == [5, 4, 4, 4, 4]
  end
end
