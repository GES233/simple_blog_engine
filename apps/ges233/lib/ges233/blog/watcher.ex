defmodule GES233.Blog.Watcher do
  alias GES233.Blog.Builder

  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def started? do
    Process.whereis(__MODULE__) != nil
  end

  def init(_init_args) do
    posts = [
      dirs: [
        Application.get_env(:ges233, :blog_root),
        Application.get_env(:ges233, :bibliography_entry)
      ],
      name: :posts
    ]

    assets = [
      dirs: [
        Application.get_env(:ges233, :Media)[:pic_path],
        Application.get_env(:ges233, :Media)[:pdf_path],
        Application.get_env(:ges233, :Media)[:dot_path]
      ],
      name: :assets
    ]

    {:ok, posts_watcher} = FileSystem.start_link(posts)
    {:ok, assets_watcher} = FileSystem.start_link(assets)

    FileSystem.subscribe(posts_watcher)
    FileSystem.subscribe(assets_watcher)

    {
      :ok,
      %{
        meta: do_init(),
        watchers: %{posts: posts_watcher, assets: assets_watcher},
        # 新增状态
        # 使用 Map 来存储 {path => event_type}
        diffs: %{},
        timer_ref: nil
      }
    }
  end

  defp do_init() do
    Builder.build_from_root()
  end

  # FileSystem related

  def handle_info(
        {:file_event, _watcher_pid, {path, events}},
        %{timer_ref: old_timer} = state
      ) do
    # 如果已经有计时器在运行，取消它
    if old_timer, do: Process.cancel_timer(old_timer)

    # 从事件列表中推断主要事件类型（例如 :created, :modified, :deleted）
    # file_system 库通常会给出 :created, :modified, :deleted, :renamed 等原子
    # 这里我们简化处理，你可以根据 file_system 库的实际输出来调整
    event_type =
      cond do
        :created in events -> :create
        :deleted in events -> :delete
        # 其他情况都视为更新
        true -> :update
      end

    # 将新的变更合并到 diffs 中
    # 如果一个文件先被创建又被修改，我们最终只关心它是被创建的
    new_diffs =
      Map.update(state.diffs, path, event_type, fn existing_event ->
        if existing_event == :create, do: :create, else: event_type
      end)

    # 启动一个新的计时器，在 500ms 后向自己发送 :process_changes 消息
    # 这个延迟时间可以配置化
    delay_ms = 500
    new_timer = Process.send_after(self(), :process_changes, delay_ms)

    # 更新状态
    new_state =
      state
      |> Map.put(:diffs, new_diffs)
      |> Map.put(:timer_ref, new_timer)

    {:noreply, new_state}
  end

  # TODO
  def handle_info(:process_changes, state) do
    IO.puts("Change detected, processing updates...")

    {:noreply, state}
  end
end
