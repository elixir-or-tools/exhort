# Exhort

Beseach the maths to answer.

## Overview

Exhort is an Elixir interface to the [Google OR
Tools](https://developers.google.com/optimization).

Currently, there are C++ (native) and Python interfaces to the Google OR tools,
with Java and C#.

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
    builder =
      Builder.new()
      |> Builder.def_int_var(:x, {0, 10})
      |> Builder.def_int_var(:y, {0, 10})
      |> Builder.def_bool_var(:b)
      |> Builder.constrain(:x, :>=, 5, if: :b)
      |> Builder.constrain(:x, :<=, 5, unless: :b)
      |> Builder.constrain(LinearExpression.sum(:x, :y), :==, 10, if: :b)
      |> Builder.constrain(:y, :==, 0, unless: :b)

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
    SolverResponse.int_val(response, :x) |> IO.inspect(label: "x: ")
    SolverResponse.int_val(response, :y) |> IO.inspect(label: "y: ")
    SolverResponse.bool_val(response, :b) |> IO.inspect(label: "b: ")
```

### Variables

Model variables are symbolic and may be either atoms or strings. This allows the
variables to be consistently referenced through a builder pipeline, for example,
without having to capture an intermediate result.

### Model

The model is the result of finalizing the builder, created throught the
`Builder.build/1` function.

The model may then be solved with `Model.solve/1` or `Model.solve/2`.

The latter function allows for a function to be passed to receive intermediate
solutions from the solver.

## Implementation

Exhort relies on the underlying native C++ implementation of the Google OR Tools.

References to the native objects are returned via NIF resources to the Elixir
runtime as `%Reference{}` values. These are often stored in corresponding Exhort
structs under the `res` key.

The native code is compiled to a single `nif.so` library and loaded via the
`Exhort.NIF.Nif` module.
