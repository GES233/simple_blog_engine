defmodule Mix.Tasks.G.Gen do
  use Mix.Task

  def run(_) do
    Mix.Task.run("app.start", [])

    GES233.exe()
  end
end
