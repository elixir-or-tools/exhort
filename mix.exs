defmodule Exhort.MixProject do
  use Mix.Project

  def project do
    [
      app: :exhort,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "Exhort",
      docs: docs(),
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
      {:elixir_make, "~> 0.4", runtime: false},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false}
    ]
  end

  defp description() do
    """
    An idiomatic Elixir library for operations research optimization.

    Exhort provides an interface to the Google OR Tools.
    """
  end

  defp docs do
    [
      main: "Exhort",
      groups_for_modules: [
        # Exhort,
        # Exhort.SAT.Builder,
        # Exhort.SAT.Expr,
        # Exhort.SAT.Model,
        # Exhort.SAT.SolverResponse,
      ],
      extras: [
        "notebooks/binpacking.livemd",
        "notebooks/nurse-scheduling.livemd",
        "notebooks/channeling.livemd",
        "notebooks/rabbits-and-pheasants.livemd",
        "notebooks/minimal-job-shop.livemd",
        "notebooks/ranking-sample-sat.livemd",
        "notebooks/multiple-knapsack.livemd"
      ]
    ]
  end

  defp package do
    [
      name: "exhort",
      organization: "elixir-or-tools",
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
      links: %{
        "GitHub" => "https://github.com/elixir-or-tools/exhort",
        "Google OR Tools" => "https://developers.google.com/optimization/"
      },
      source_url: "https://github.com/elixir-or-tools/exhort"
    ]
  end
end
