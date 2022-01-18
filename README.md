# Exhort

Beseach the maths to answer.

## Overview

Exhort is an Elixir interface to the [Google OR
Tools](https://developers.google.com/optimization).

Currently, there are C++ (native) Python, Java and C# interfaces to the Google
OR tools.

Exhort is similar to the non-native interfaces to the tooling, but uses
[NIFs](https://www.erlang.org/doc/tutorial/nif.html) instead of
[SWIG](http://www.swig.org/) to interface with the native libarary.

The goal of Exhort is to provide an idomatic Elixir interface to the Google OR
Tools.

## Setup

Because Exhort uses the Google OR tools, the first step is to install them on
the target system.

### MacOS

On MacOS, ensure the latest command line tools are installed. Currently, 13.2 is
the latest. You can check with:

```sh
$ pkgutil --pkg-info=com.apple.pkg.CLTools_Executables
```

https://developer.apple.com/download/all/

If there's a problem updating your tools, you might have to do it manually.

1. Remove existing files with `sudo rm -rf /Library/Developer/CommandLineTools`
2. Install the package above.

Next, install the or-tools from Homebrew:

```sh
$ brew install or-tools
```

Then:

```sh
$ mix compile
$ mix test
```

## Getting Started

The easiest way to get started is with the sample Livebook notebooks in the
`notebooks` directory.

Start [Livebook](https://livebook.dev/) and open a notebook (use whatever method
you like to start Livebook).

```sh
$ mix escript.install hex livebook
# if installed in `asdf` use `asdf reshim`
$ livebook server --name livebook@127.0.0.1
```

1. Use the link that is written to the console and browse the samples.
2. Open a sample in the `notebooks` directory
3. Run the notebook in the project by choosing the `Mix standalone` option in the
   left side of Livebook under "Runtime setteings"

That should provide a starting place for exploring the Exhort API and expression
language.

## API

Exhort is in the early stages of development. As such, we are investigating a
varity of API approaches. We may end up with more than one (a la Ecto), but in
the short term will likely focus on a single approach.

### Builder

Building a model starts off with the `Builder`.

`Builder` has functions for defining variables, specifying constraints and
creating the model using the `build` function.

The result of the `build` function is a `Model`.

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
    response.status |> IO.inspect(label: "satus: ")
    # 10, 0, true
    SolverResponse.int_val(response, "x") |> IO.inspect(label: "x: ")
    SolverResponse.int_val(response, "y") |> IO.inspect(label: "y: ")
    SolverResponse.bool_val(response, "b") |> IO.inspect(label: "b: ")
```

### Expr

Sometimes it may be more convenient to build up expressions separately and then
add them to a `%Builer{}` all at once. This is often the case when more complex
data sets are invovled in generating many variables and constraints for the
model.

Instead of having to maintain the builder through an `Enum.reduce/3` construct
like this:

```elixir
    builder =
      Enum.reduce(all_days, builder, fn day, builder ->
        Enum.reduce(all_shifts, builder, fn shift, builder ->
          shift_options = Enum.filter(shifts, fn {_n, d, s} -> d == day and s == shift end)
          shift_option_vars = Enum.map(shift_options, fn {n, d, s} -> "shift_#{n}_#{d}_#{s}" end)

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

Model variables are symbolic, represented as strings or atoms, and so don't
interfere to the surrounding Elixir context. This allows the variables to be
consistently referenced through a builder pipeline, for example, without having
to capture an intermediate result.

Elixir variables may be used "as is" in expressions, allowing variables to be
generated from enumerable collections.

In the following expression, `"x"` is a model variable, while `y` is an Elixir
variable:

```elixir
"x" < y + 3
```

Building variables is done through normal Elixir expressions:

```elixir
    builder
    |> Builder.reduce(all_bins, fn bin, builder ->
      Builder.def_bool_var(builder, "slack_#{bin}")
    end)
```

Note the use of `Builder.reduce/3` here. That function delegates to
`Enum.reduce`, but uses the `%Builder{}` as its first argument, making it
convenient for pipelining.

Of course, such names are still usable in expressions:

```elixir
    builder
    |> Builder.constrain("slack_#{bin}" <= bin_total)
```

### Expressions

Exhort supports a limited set of expressions. Expressions may use the binary
operators `+`, `-` and `*`, with their traditional mathematical meaning. They
may also use comparison operators `<`, `<=`, `==`, `>=`, `>`, the `sum` function
and even the `for` comprehension.

```elixir
    builder
    |> Builder.reduce(all_bins, fn bin, builder ->
      expr = Enum.map(items, &{elem(&1, 0), "x_#{elem(&1, 0)}_#{bin}"})
      load_bin = "load_#{bin}"

      builder
      |> Builder.constrain(sum(for {item, x} <- expr, do: item * x) == load_bin)
    end)
```

### Model

The model is the result of finalizing the builder, created throught the
`Builder.build/1` function.

The model may then be solved with `Model.solve/1` or `Model.solve/2`.

The latter function allows for a function to be passed to receive intermediate
solutions from the solver.

## Implementation

Exhort relies on the underlying native C++ implementation of the Google OR
Tools.

References to the native objects are returned via NIF resources to the Elixir
runtime as `%Reference{}` values. These are often stored in corresponding Exhort
structs under the `res` key.

The native code is compiled to a single `nif.so` library and loaded via the
`Exhort.NIF.Nif` module.
