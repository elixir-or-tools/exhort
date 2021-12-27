defmodule Exhort.SAT.SolverResponseTest do
  use ExUnit.Case

  alias Exhort.SAT.Model
  alias Exhort.SAT.SolverResponse

  test "build/2" do
    assert %SolverResponse{status: :optimal} =
             SolverResponse.build(
               %{
                 "res" => make_ref(),
                 "status" => 4,
                 "objective" => 1.0,
                 "walltime" => 2.0,
                 "usertime" => 3.0
               },
               %Model{}
             )
  end

  test "stats/1" do
    assert %{status: :optimal, objective: 1.0, walltime: 2.0, usertime: 3.0} =
             SolverResponse.build(
               %{
                 "res" => make_ref(),
                 "status" => 4,
                 "objective" => 1.0,
                 "walltime" => 2.0,
                 "usertime" => 3.0
               },
               %Model{}
             )
             |> SolverResponse.stats()
  end
end
