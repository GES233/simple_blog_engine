defmodule Mix.Tasks.G.Gen do
  use Mix.Task

  require Logger

  def run(_) do
    Application.get_env(:ges233, :saved_path)
    |> File.exists?()
    |> unless(do: File.mkdir!(Application.get_env(:ges233, :saved_path)))

    opts = [strategy: :one_for_one, name: GES233.Supervisor]

    {:ok, _supervisor_id} = Supervisor.start_link([{GES233.Blog.ContentRepo, []}], opts)

    # 执行最开始的一次构建任务
    Logger.info("Performing initial site build...")
    _initial_context = GES233.Blog.Builder.build_from_root()
    Logger.info("Initial build complete.")
  end
end
