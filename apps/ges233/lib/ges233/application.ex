defmodule GES233.Application do
  @moduledoc false

  use Application

  def start(_start_type, _start_args) do
    # Create `/generated` folder if not exist.
    Application.get_env(:ges233, :saved_path)
    |> File.exists?()
    |> unless(do: File.mkdir!(Application.get_env(:ges233, :saved_path)))

    children = childrens()

    opts = [strategy: :one_for_one, name: GES233.Supervisor]

    Supervisor.start_link(children, opts)
  end

  defp childrens(_options \\ []) do
    server? =
      if Application.get_env(:ges233, :saved_path) |> File.ls!() |> length() > 0 do
        [{Bandit, scheme: :http, plug: GES233.Blog.SimpleServer}]
      else
        []
      end

    [
      {GES233.Blog.Post.ContentRepo, []},
      # {GES233.Blog.Watcher, []}
    ] ++ server?
  end
end
