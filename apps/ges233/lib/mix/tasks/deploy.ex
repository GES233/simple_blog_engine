defmodule Mix.Tasks.G.Deploy do
  use Mix.Task

  def run(_) do
    GES233.Deploy.exec()
  end
end
