defmodule GES233 do
  @moduledoc """
  Documentation for `GES233`.
  """

  use Application

  require Logger

  def start(_start_type, _start_args) do
    # Create `/generated` folder if not exist.
    Application.get_env(:ges233, :saved_path)
    |> File.exists?()
    |> unless(do: File.mkdir!(Application.get_env(:ges233, :saved_path)))

    children = [
      {GES233.Blog.ContentRepo, []},
      {GES233.Broadcaster, []}
    ]

    opts = [strategy: :one_for_one, name: GES233.Supervisor, max_seconds: 30]

    {:ok, supervisor_id} = Supervisor.start_link(children, opts)

    # 执行最开始的一次构建任务
    Logger.info("Performing initial site build...")
    {elapse, initial_context} = :timer.tc(&GES233.Blog.Builder.build_from_root/0, :millisecond)
    Logger.info("Initial build complete, elapsed #{inspect(elapse)} ms.")

    watcher_spec = {GES233.Watcher, initial_context}
    {:ok, _watcher_pid} = Supervisor.start_child(GES233.Supervisor, watcher_spec)

    if Application.get_env(:ges233, :saved_path) |> File.ls!() |> length() > 0 do
      server_spec = {Bandit, scheme: :http, plug: GES233.SimpleServer, ip: :any, port: 6969}
      {:ok, _server_pid} = Supervisor.start_child(GES233.Supervisor, server_spec)
      Logger.info("Web server started.")
    end

    if Mix.env() == :dev do
      dev_watchers()
    end

    {:ok, supervisor_id}
  end

  defp dev_watchers() do
    Logger.info("Starting file watchers for development...")

    watchers = [
      # esbuild: {Esbuild, :install_and_run, [:ges233, ~w(--sourcemap=inline --watch)]},
      tailwind: {Tailwind, :install_and_run, [:ges233, ~w(--watch)]}
    ]

    for {_name, {module, function, args}} <- watchers do
      Task.start_link(fn -> apply(module, function, args) end)
    end
  end

  # ========

  def exe() do
    GES233.Blog.Builder.build_from_root()

    :ok
  end

  def deploy(), do: GES233.Deploy.exec(true)
  def deploy(msg), do: GES233.Deploy.exec(true, msg)
end
