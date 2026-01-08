defmodule Blog.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: [
        deploy_all_in_one: &deploy_all_in_one/1
      ]
    ]
  end

  def deploy_all_in_one(_) do
    Mix.env(:prod)
    Mix.Task.run(
      "tailwind",
      ~w(
        default
        --input=apps/ges233/assets/css/app.css
        --minify
        --output=priv/generated/assets/css/app.css)
    )
    Mix.Task.run("g.gen")
    Mix.Task.run("g.deploy")
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    []
  end
end
