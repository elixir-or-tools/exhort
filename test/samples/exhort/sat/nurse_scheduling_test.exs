defmodule Samples.Exhort.SAT.NurseScheduling do
  use ExUnit.Case

  alias Exhort.SAT.Builder
  alias Exhort.SAT.LinearExpression
  alias Exhort.SAT.Model

  test "nurse scheduling" do
    num_nurses = 4
    num_shifts = 3
    num_days = 3
    all_nurses = 1..num_nurses
    all_shifts = 1..num_shifts
    all_days = 1..num_days

    acc = %{
      builder: Builder.new(),
      shifts: []
    }

    %{
      builder: builder,
      shifts: shifts
    } =
      Enum.reduce(all_nurses, acc, fn nurse, acc ->
        Enum.reduce(all_days, acc, fn day, acc ->
          Enum.reduce(all_shifts, acc, fn shift, %{builder: builder, shifts: shifts} = acc ->
            shifts = shifts ++ [{nurse, day, shift}]
            builder = Builder.def_bool_var(builder, "shift_#{nurse}_#{day}_#{shift}")

            %{
              acc
              | builder: builder,
                shifts: shifts
            }
          end)
        end)
      end)

    builder =
      Enum.reduce(all_days, builder, fn day, builder ->
        Enum.reduce(all_shifts, builder, fn shift, builder ->
          shift_options = Enum.filter(shifts, fn {_n, d, s} -> d == day and s == shift end)
          shift_option_vars = Enum.map(shift_options, fn {n, d, s} -> "shift_#{n}_#{d}_#{s}" end)

          Builder.constrain(builder, LinearExpression.sum(shift_option_vars), :==, 1)
        end)
      end)

    builder =
      Enum.reduce(all_nurses, builder, fn nurse, builder ->
        Enum.reduce(all_days, builder, fn day, builder ->
          shift_options = Enum.filter(shifts, fn {n, d, _s} -> n == nurse and d == day end)
          shift_option_vars = Enum.map(shift_options, fn {n, d, s} -> "shift_#{n}_#{d}_#{s}" end)

          Builder.constrain(builder, LinearExpression.sum(shift_option_vars), :<=, 1)
        end)
      end)

    min_shifts_per_nurse = div(num_shifts * num_days, num_nurses)

    max_shifts_per_nurse =
      if rem(num_shifts * num_days, num_nurses) == 0 do
        min_shifts_per_nurse
      else
        min_shifts_per_nurse + 1
      end

    builder =
      Enum.reduce(all_nurses, builder, fn nurse, builder ->
        shift_options = Enum.filter(shifts, fn {n, _d, _s} -> n == nurse end)
        shift_option_vars = Enum.map(shift_options, fn {n, d, s} -> "shift_#{n}_#{d}_#{s}" end)

        builder
        |> Builder.constrain(min_shifts_per_nurse, :<=, LinearExpression.sum(shift_option_vars))
        |> Builder.constrain(LinearExpression.sum(shift_option_vars), :<=, max_shifts_per_nurse)
      end)

    assert :optimal ==
             builder
             |> Builder.build()
             |> Model.solve()
             |> then(& &1.status)
  end
end
