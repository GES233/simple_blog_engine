defmodule GES233.Application do
  @moduledoc false

  use Application

  require Logger

  def start(_start_type, _start_args) do
    # Create `/generated` folder if not exist.
    Application.get_env(:ges233, :saved_path)
    |> File.exists?()
    |> unless(do: File.mkdir!(Application.get_env(:ges233, :saved_path)))

    children = [{GES233.Blog.ContentRepo, []}]

    opts = [strategy: :one_for_one, name: GES233.Supervisor]

    {:ok, supervisor_id} = Supervisor.start_link(children, opts)

    # 执行最开始的一次构建任务
    Logger.info("Performing initial site build...")
    initial_context = GES233.Blog.Builder.build_from_root()
    Logger.info("Initial build complete.")

    watcher_spec = {GES233.Blog.Watcher, initial_context}
    {:ok, _watcher_pid} = Supervisor.start_child(GES233.Supervisor, watcher_spec)

    if Application.get_env(:ges233, :saved_path) |> File.ls!() |> length() > 0 do
      server_spec = {Bandit, scheme: :http, plug: GES233.Blog.SimpleServer}
      {:ok, _server_pid} = Supervisor.start_child(GES233.Supervisor, server_spec)
      Logger.info("Starting web server.")
    end

    {:ok, supervisor_id}
  end
end
