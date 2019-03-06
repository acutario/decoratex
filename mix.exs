defmodule Decoratex.Mixfile do
  use Mix.Project

  @version "1.1.0"

  def project do
    [
      app: :decoratex,
      version: @version,
      elixir: "~> 1.4",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      # Docs
      name: "Decoratex",
      description: description(),
      package: package()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ecto, "~> 3.0"},
      {:ex_doc, "~> 0.11", only: :dev},
      {:earmark, "~> 0.1", only: :dev},
      {:dialyxir, "~> 0.3", only: :dev},
      {:credo, "~> 0.4", only: [:dev, :test]}
    ]
  end

  # Always compile files in "lib". In tests compile also files in
  # "test/support"
  def elixirc_paths(:test), do: elixirc_paths() ++ ["test/support"]
  def elixirc_paths(_), do: elixirc_paths()
  def elixirc_paths, do: ["lib"]

  defp description do
    """
    Decoratex provides an easy way to add calculated data to your Ecto model structs.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["Rubén Sierra González"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/acutario/decoratex"}
    ]
  end
end
