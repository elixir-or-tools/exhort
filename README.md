# Exhort

Beseech the maths to answer.

## Overview

Exhort is an Elixir interface to the [Google OR
Tools](https://developers.google.com/optimization).

Currently, there are C++ (native) Python, Java and C# interfaces to the Google
OR tools.

Exhort is similar to the non-native interfaces to the tooling, but Exhort uses
[NIFs](https://www.erlang.org/doc/tutorial/nif.html) instead of
[SWIG](http://www.swig.org/) to interface with the native libarary.

The goal of Exhort is to provide an idomatic Elixir interface to the Google OR
Tools.

## Setup

Because Exhort uses the Google OR tools, the first step is to install them on
the target system.

### MacOS

On MacOS, ensure the [latest command line
tools](https://developer.apple.com/download/all/) are installed.

```sh
pkgutil --pkg-info=com.apple.pkg.CLTools_Executables
```

Next, install the `or-tools` package from Homebrew:

```sh
brew install or-tools
```

Then leverage `asdf` for the required versions of Elixir and Elang:

```sh
asdf install
```

Finally, export the locations of Erlang and the OR Tools:

```sh
export ERLANG_HOME=$HOME/.asdf/installs/erlang/24.2.1
export ORTOOLS=/usr/local
```

### Debian

Follow the instructions
[here](https://developers.google.com/optimization/install/cpp/linux) and install
from the appropriate archive. You will likely want to install them in a
reasonable place like `/usr/local/lib` and perhaps link them to a consistent
path.

For example:

```sh
wget https://github.com/google/or-tools/releases/download/v9.2/or-tools_amd64_debian-11_v9.2.9972.tar.gz
tar xf or-tools_amd64_debian-11_v9.2.9972.tar.gz -C /usr/local/lib
ln -s /usr/local/lib/or-tools_Debian-11-64bit_v9.2.9972 /usr/local/lib/ortools
```

Then export the locations of Erlang and the OR Tools:

```sh
export ERLANG_HOME=/usr/local/lib/erlang
export ORTOOLS=/usr/local/lib/ortools
```

### Compiling

Exhort uses NIFs for interfacing with the Google OR tools. This means that
Exhort NIFs must be compiled using a C compiler and Make. The `Makefile`
contains these instructions. It just needs to know where you have installed both
Erlang and the Google OR Tools. It will use the environment variables you
exported above.

```sh
mix compile
mix test
```

## Getting Started

The easiest way to get started is with the sample Livebook notebooks in the
`notebooks` directory.

Start [Livebook](https://livebook.dev/) and open a notebook (use whatever method
you like to start Livebook).

```sh
mix escript.install hex livebook
# if installed in `asdf` use `asdf reshim`
livebook server --name livebook@127.0.0.1
```

1. Use the link that is written to the console and browse the samples.
2. Open a sample in the `notebooks` directory
3. Run the notebook in the project by choosing the `Mix standalone` option in
   the left side of Livebook under "Runtime setteings"

The notebooks are mostly implementations of some of the samples that come with
the Google OR Tools. That should provide a starting place for exploring the
Exhort API and expression language. There is more about the Exhort API and
expression language below, but the notebooks and tests are probably a good place
to start.

## API

Exhort is in the early stages of development. As such, we are investigating a
varity of API approaches. We may end up with more than one (a la Ecto), but in
the short term will likely focus on a single approach.

The API is centered around the `Builder` and `Expr` modules. Those modules
leverage Elixir macros to provide a DSL "expression language" for Exhort.

### Builder

Building a model starts off with the `Builder`.

`Builder` has functions for defining variables, specifying constraints and
creating a `%Model{}` using the `build` function.

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
    response.status |> IO.inspect(label: "satus: ")
    # 10, 0, true
    SolverResponse.int_val(response, "x") |> IO.inspect(label: "x: ")
    SolverResponse.int_val(response, "y") |> IO.inspect(label: "y: ")
    SolverResponse.bool_val(response, "b") |> IO.inspect(label: "b: ")
```

See below for more about the expression language used in Exhort.

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

Model variables in the expression language are symbolic, represented as strings
or atoms, and so don't interfere to the surrounding Elixir context. This allows
the variables to be consistently referenced through a builder pipeline, for
example, without having to capture an intermediate result.

Elixir variables may be used "as is" in expressions, allowing variables to be
generated from enumerable collections.

In the following expression, `"x"` is a model variable, while `y` is an Elixir
variable:

```elixir
"x" < y + 3
```

Variables may be defined in a few ways. It's often convenient to just focus on
the `Expr` and `Builder` modules, which each have functions like `def_int_var`
and `def_bool_var`.

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

Note that any variables or expressions created outside of the `Builder` still
need to be added to a `%Builder{}` struct for them to be part of the model
resulting from `build/1`. There's no magic here, these are still Elixir
immutable data structures.

```elixir
    variables = ...
    expressions = ...

    Builder.new()
    |> Builder.add(variables)
    |> Builder.add(expressions)
    |> Builder.build()
```

### Expressions

Exhort supports a limited set of expressions. Expressions may use the binary
operators `+`, `-` and `*`, with their traditional mathematical meaning. They
may also use comparison operators `<`, `<=`, `==`, `>=`, `>`, the `sum` function
and even the `for` comprehension.

```elixir
    all_bins
    |> Enum.map(fn bin ->
      vars = Enum.map(items, &{elem(&1, 0), "x_#{elem(&1, 0)}_#{bin}"})
      load_bin = "load_#{bin}"

      Expr.constrain(sum(for {item, x} <- vars, do: item * x) == load_bin)
    end)
```

### Model

The model is the result of finalizing the builder, created through the
`Builder.build/1` function.

The model may then be solved with `Model.solve/1` or `Model.solve/2`.

The latter function allows for a function to be passed to receive intermediate
solutions from the solver.

## Implementation

Exhort relies on the underlying native C++ implementation of the Google OR
Tools.

Exhort interacts with the Google OR Tools library when the model is built using
`Builder.build/1` and when solved using `Model.solve/1` or `Model.solve/2`.

References to the native objects are returned via NIF resources to the Elixir
runtime as `%Reference{}` values. These are often stored in corresponding Exhort
structs under the `res` key.

The native code is compiled to a single `nif.so` library and loaded via the
`Exhort.NIF.Nif` module.
