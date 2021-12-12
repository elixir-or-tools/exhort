# ElixOr

**TODO: Add description**

## Setup

Get the Command Line Tools for macOS v13.1:
https://developer.apple.com/download/all/

There may be a better way to do this but:

1. Remove existing files with `sudo rm -rf /Library/Developer/CommandLineTools`
2. Install the package above.

Next, install the or-tools from Homebrew:

```sh
$ brew install or-tools
```

```sh
$ mix compile
$ mix test
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `elix_or` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elix_or, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/elix_or>.

## DSL?

1. Consider building up the model without integrating with the underlying native model.
    - beneift of pure functions
    - consequence of not validating things until the build step
2. Use atoms instead of variables to enable pipelines
    - Otherwise, might need to use macros for a DSL

```elixir
    response =
      CpModelBuilder.new()
      |> CpModelBuilder.new_int_var([x], 0, 2)
      |> CpModelBuilder.new_int_var([y], 0, 2)
      |> CpModelBuilder.new_int_var([z], 0, 2)
      |> CpModelBuilder.add_not_equal([x, y], x, y)
      |> CpModelBuilder.solve()
```

Simpler?

```elixir
    response =
      CpModelBuilder.new()
      |> CpModelBuilder.new_int_var(:x, 0, 2)
      |> CpModelBuilder.new_int_var(:y, 0, 2)
      |> CpModelBuilder.new_int_var(:z, 0, 2)
      |> CpModelBuilder.add_not_equal(:x, :y)
      |> CpModelBuilder.solve()
```

```elixir
    response =
      new(
        int_var: x in {0, 2},
        int_var: y in {0, 2},
        not_equal: {x, y},
      )
      |> CpModelBuilder.solve()
```

Simpler?

```elixir
    response =
      CpModelBuilder.new(
        int_var: {:x, 0, 2},
        int_var: {:y, 0, 2},
        not_equal: {:x, :y},
      )
      |> CpModelBuilder.solve()
```
