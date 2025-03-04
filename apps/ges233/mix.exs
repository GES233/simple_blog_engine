defmodule GES233.MixProject do
  use Mix.Project

  def project do
    [
      app: :ges233,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {GES233.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_html, "~> 3.3.4"},
      {:plug, "~> 1.16"},
      {:bandit, "~> 1.0"},
      {:yaml_elixir, "~> 2.11"},
      {:pandox, in_umbrella: true}
    ]
  end
end
