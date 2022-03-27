defmodule Exhort do
  @moduledoc ~S"""
  Exhort is an idomatic Elixir interface to the [Google OR
  Tools](https://developers.google.com/optimization/).

  Exhort is currently focused on the "SAT" portion of the tooling:

  > A constraint programming solver that uses SAT (satisfiability) methods.

  The primary API for Exhort is through a few modules:

  * `Exhort.SAT.Builder` - The module and struct for building a
  `Exhort.SAT.Model`. The builder provides functions for defining variables,
  expressions and building the model.

  * `Exhort.SAT.Expr` - A factory for expressions, constraints and variables.
    This module may be used as the primary interface for defining the parts of a
    model which are then added to a `%Exhort.SAT.Builder{}` struct before
    building the model.

  * `Exhort.SAT.Model` - The result of building a model through
    `Exhort.SAT.Builder.build/1`. Solving the model is done with
    `Exhort.SAT.Model.solve/1` or `Exhort.SAT.Model.solve/2`. The latter accepts
    a function that receives intermediate results in the solution.

  * `Exhort.SAT.SolverResponse` - A model solution. The
    `%Exhort.SAT.SolverResponse{}` struct containts meta-level information of
    the solution. The module has functions for retriving the values of variables
    defined in the model.

  ## Livebook

  See the included sample Livebook notebooks for examples on using Exhort.

  ## Setup

  See the Exhort README for information on using Exhort in a Livebook or adding
  it as a dependency to a project. Exhort uses native code so the host systsem
  must have a C/C++ compiler and the `make` utility.

  ## API

  Exhort is in the early stages of development. As such, we are investigating a
  varity of API approaches. We may end up with more than one (a la Ecto), but in
  the short term will likely focus on a single approach.

  The API is centered around the `Builder` and `Expr` modules. Those modules
  leverage Elixir macros to provide a DSL "expression language" for Exhort.

  ### Builder

  Building a model is done `Exhort.SAT.Builder`.

  `Exhort.SAT.Builder` has functions for defining variables, specifying
  constraints and creating a `%Exhort.SAT.Model{}` using the `build` function.

  By specifying `use Exhort.SAT.Builder`, all of the relevant modules will be
  aliased and the Exhort macros will be expanded.

  ```elixir
    use Exhort.SAT.Builder
    ...

      builder =
        Builder.new()
        |> Builder.def_int_var("x", {0, 10})
        |> Builder.def_int_var("y", {0, 10})
        |> Builder.def_bool_var("b")
        |> Builder.constrain("x" >= 5, if: "b")
        |> Builder.constrain("x" < 5, unless: "b")
        |> Builder.constrain("x" + "y" == 10, if: "b")
        |> Builder.constrain("y" == 0, unless: "b")

      {response, acc} =
        builder
        |> Builder.build()
        |> Model.solve(fn
          _response, nil -> 1
          _response, acc -> acc + 1
        end)

      # 2 responses
      acc |> IO.inspect(label: "acc: ")
      response |> IO.inspect(label: "response: ")

      # :optimal
      response.status |> IO.inspect(label: "status: ")
      # 10, 0, true
      SolverResponse.int_val(response, "x") |> IO.inspect(label: "x: ")
      SolverResponse.int_val(response, "y") |> IO.inspect(label: "y: ")
      SolverResponse.bool_val(response, "b") |> IO.inspect(label: "b: ")
  ```

  See below for more about the expression language used in Exhort.

  ### Expr

  Sometimes it may be more convenient to build up expressions separately and
  then add them to a `%Builer{}` all at once. This is often the case when more
  complex data sets are invovled in generating many variables and constraints
  for the model.

  Instead of having to maintain the builder through an `Enum.reduce/3` construct
  like this:

  ```elixir
    builder =
      Enum.reduce(all_days, builder, fn day, builder ->
        Enum.reduce(all_shifts, builder, fn shift, builder ->
          shift_option_vars =
            shifts
            |> Enum.filter(fn {_n, d, s} -> d == day and s == shift end)
            |> Enum.map(fn {n, d, s} -> "shift_#{n}_#{d}_#{s}" end)

          Builder.constrain(builder, sum(shift_option_vars) == 1)
        end)
      end)
  ```

  Exhort allows the generation of lists of variables or constraint, maybe using
  `Enum.map/2`:

  ```elixir
    shift_nurses_per_period =
      Enum.map(all_days, fn day ->
        Enum.map(all_shifts, fn shift ->
          shift_options = Enum.filter(shifts, fn {_n, d, s} -> d == day and s == shift end)
          shift_option_vars = Enum.map(shift_options, fn {n, d, s} -> "shift_#{n}_#{d}_#{s}" end)

          Expr.new(sum(shift_option_vars) == 1)
        end)
      end)
      |> List.flatten()
  ```

  These may then be added to the builder as a list:

  ```elixir
    builder
    |> Builder.add(shift_nurses_per_period)
  ...
  ```

  ### Variables

  Model variables in the expression language are symbolic, represented as
  strings or atoms, and so don't interfere to the surrounding Elixir context.
  This allows the variables to be consistently referenced through a builder
  pipeline, for example, without having to capture an intermediate result.

  Elixir variables may be used "as is" in expressions, allowing variables to be
  generated from enumerable collections.

  In the following expression, `"x"` is a model variable, while `y` is an Elixir
  variable:

  ```elixir
    "x" < y + 3
  ```

  Variables may be defined in a few ways. It's often convenient to just focus on
  the `Exhort.SAT.Expr` and `Exhort.SAT.Builder` modules, which each have
  functions like `def_int_var` and `def_bool_var`.

  ```elixir
    all_bins
    |> Enum.map(fn bin ->
      Expr.def_bool_var("slack_#{bin}")
    end)
  ```

  However, `BoolVar.new/1` and `IntVar.new/1` may also be used:

  ```elixir
    all_bins
    |> Enum.map(fn bin ->
      BoolVar.new("slack_#{bin}")
    end)
  ```

  Of course, such names are still usable in expressions:

  ```elixir
    Expr.new("slack_#{bin}" <= bin_total)
  ```

  Note that any variables or expressions created outside of the
  `Exhort.SAT.Builder` still need to be added to a `%Exhort.SAT.Builder{}`
  struct for them to be part of the model resulting from `build/1`. There's no
  magic here, these are still Elixir immutable data structures.

  ```elixir
    variables = ...
    expressions = ...

    Builder.new()
    |> Builder.add(variables)
    |> Builder.add(expressions)
    |> Builder.build()
  ```

  ## Expressions

  Exhort supports a limited set of expressions. Expressions may use the binary
  operators `+`, `-` and `*`, with their traditional mathematical meaning. They
  may also use comparison operators `<`, `<=`, `==`, `>=`, `>`, the `sum`
  function and even the `for` comprehension.

  ```elixir
    all_bins
    |> Enum.map(fn bin ->
      vars = Enum.map(items, &{elem(&1, 0), "x_#{elem(&1, 0)}_#{bin}"})
      load_bin = "load_#{bin}"

      Expr.constrain(sum(for {item, x} <- vars, do: item * x) == load_bin)
    end)
  ```

  ## Model

  The model is the result of finalizing the builder, created through the
  `Exhort.SAT.Builder.build/1` function.

  The model may then be solved with `Exhort.SAT.Model.solve/1` or
  `Exhort.SAT.Model.solve/2`.

  The latter function allows for a function to be passed to receive intermediate
  solutions from the solver.

  ## SolverResponse

  The result of `Exhort.SAT.Model.solve/1` is a `%Exhort.SAT.SolverResponse{}`.
  The response containts meta-level information of the solution.
  `Exhort.SAT.SolverResponse` has functions for retriving the values of
  variables defined in the model.

  ```elixir
    response =
      Builder.new()
      |> Builder.def_int_var("r", {0, 100})
      |> Builder.def_int_var("p", {0, 100})
      |> Builder.constrain("r" + "p" == 20)
      |> Builder.constrain(4 * "r" + 2 * "p" == 56)
      |> Builder.build()
      |> Model.solve()

    assert :optimal = response.status
    assert 8 == SolverResponse.int_val(response, "r")
    assert 12 == SolverResponse.int_val(response, "p")
  ```

  ## Implementation

  Exhort relies on the underlying native C++ implementation of the Google OR
  Tools.

  Exhort interacts with the Google OR Tools library when the model is built
  using `Builder.build/1` and when solved using `Model.solve/1` or
  `Model.solve/2`.

  References to the native objects are returned via NIF resources to the Elixir
  runtime as `%Reference{}` values. These are often stored in corresponding
  Exhort structs under the `res` key.
  """
end
