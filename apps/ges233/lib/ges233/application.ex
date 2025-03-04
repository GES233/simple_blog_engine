defmodule GES233.Application do
  @moduledoc false

  use Application

  def start(_start_type, _start_args) do
    children = childrens()

    opts = [strategy: :one_for_one, name: GES233.Supervisor]

    Supervisor.start_link(children, opts)
  end

  defp childrens(_options \\ []) do
    [
      {Bandit, scheme: :http, plug: GES233.Blog.SimpleServer, options: [port: 4000]},
      {GES233.Blog.Post.ContentRepo, []}
    ]
  end
end
