defmodule Exhort.MixProject do
  use Mix.Project

  def project do
    [
      app: :exhort,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      compilers: [:elixir_make] ++ Mix.compilers(),
      make_args: ["--quiet"],
      make_clean: ["clean"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:elixir_make, "~> 0.4", runtime: false}
    ]
  end

  defp package do
    [
      name: "exhort",
      description: "An idiomatic Elixir library for operations research optmization",
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "LICENSE.md",
        "c_src/*.[cc]",
        "c_src/*.h",
        "Makefile"
      ],
      maintainers: ["objectuser", "cameron-kurth"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/elixir-or-tools/exhort"}
    ]
  end
end
