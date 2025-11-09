defmodule GES233.MixProject do
  use Mix.Project

  def project do
    [
      app: :ges233,
      version: "0.3.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {GES233, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_html, "~> 3.3.4"},
      {:plug, "~> 1.16"},
      {:bandit, "~> 1.0"},
      {:yaml_elixir, "~> 2.11"},
      {:pandox, in_umbrella: true},
      {:file_system, "~> 1.0"},
      {:git_cli, "~> 0.3.0"},
      {:tz, "~> 0.28"},
      {:jason, "~> 1.4"},
      ## 前端相关
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1}
    ]
  end

  defp aliases do
    [
      "assets.setup": [
        "tailwind.install --if-missing",
        # "esbuild.install --if-missing"
      ],
      "assets.build": [
        "compile",
        "tailwind ges233",
        # "esbuild ges233"
      ],
      "assets.deploy": [
        "tailwind gse233 --minify",
        # "esbuild gse233 --minify",
      ]
    ]
  end
end
