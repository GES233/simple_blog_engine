defmodule GES233.Blog.Watcher do
  use GenServer

  require Logger

  import GES233.Blog.Post.RegistryBuilder,
    only: [
      get_posts_root_path: 0,
      get_pic_entry: 0,
      get_pdf_entry: 0,
      get_dot_entry: 0
    ]

  import GES233.Blog.Bibliography, only: [get_bibliography_entry: 0]

  alias GES233.Blog.{Media, Post}

  def start_link(initial_context) do
    GenServer.start_link(__MODULE__, initial_context, name: __MODULE__)
  end

  def started? do
    Process.whereis(__MODULE__) != nil
  end

  def init(initial_context) do
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
        meta: initial_context,
        watchers: %{posts: posts_watcher, assets: assets_watcher},
        # 新增状态
        # 使用 Map 来存储 {path => event_type}
        diffs: %{},
        timer_ref: nil
      }
    }
  end

  # FileSystem related

  def handle_info(
        {:file_event, _watcher_pid, {raw_path, events}},
        %{timer_ref: old_timer} = state
      ) do
    path = normalize_path(raw_path)

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

    # state |> IO.inspect()
    # {absolutely_path => [event_type]}
    # 现在的情况是不需要那么细粒度的处理
    # 只需要告诉是文档还是资源有更新即可
    changed_paths = Map.keys(state.diffs)

    ## 当务之急是对变化进行分类
    #
    # - media(-> meta_registry)
    # - bibloigraphy&posts(-> posts)
    # - pages(-> index_registry)
    classified_changes = Enum.group_by(changed_paths, &classify_path/1) |> IO.inspect()

    Logger.debug(fn -> "Classified changes: #{inspect(classified_changes)}" end)

    post_changes = Map.get(classified_changes, :post, [])
    bib_changes = Map.get(classified_changes, :bib, [])
    media_changes = Map.get(classified_changes, :media, [])
    # page_changes = Map.get(classified_changes, :page, [])
    unclassified = Map.get(classified_changes, nil, [])

    if unclassified != [],
      do: Logger.info("Ignoring unclassified files: #{inspect(unclassified)}")

    current_context = state.meta

    new_context =
      current_context
      |> handle_media_changes(media_changes)
      |> handle_content_changes(post_changes, bib_changes)

    # |> handle_page_changes(page_changes)

    IO.puts("Update complete")

    # 重置状态并返回
    {:noreply, %{state | meta: new_context, diffs: %{}, timer_ref: nil}}
  end

  def handle_info(msg, state) do
    IO.inspect(msg)

    {:noreply, state}
  end

  defp classify_path(path) do
    # Enum.find_value 会遍历我们的规则列表，
    # 找到第一个匹配的规则，并返回其分类名。
    # 如果没有找到，它会返回 nil。
    Enum.find_value(category_definitions(), fn {category, base_path} ->
      if String.starts_with?(path, base_path), do: category
    end)
  end

  defp handle_media_changes(context, []), do: context

  defp handle_media_changes({meta_registry, index_registry}, media_paths) do
    Logger.info("Processing #{length(media_paths)} media file change(s)...")

    # 1. 重新解析变化的媒体文件
    updated_media =
      media_paths
      |> Enum.map(&Media.parse_media/1)
      |> Map.new(fn m -> {m.id, m} end)

    # 2. 更新 meta_registry
    new_meta_registry = Map.merge(meta_registry, updated_media)

    # 3. 把新文件复制到目标目录
    # Builder.copy_assets(Map.values(updated_media))

    # 4. 返回更新后的上下文
    {new_meta_registry, index_registry}
  end

  defp handle_content_changes(context, [], []), do: context

  defp handle_content_changes({meta_registry, index_registry}, post_paths, bib_paths) do
    Logger.info(
      "Processing #{length(post_paths)} post(s) and #{length(bib_paths)} bib file change(s)..."
    )

    # 1. 重新解析变化的 Post
    updated_posts =
      post_paths
      |> Task.async_stream(&Post.path_to_struct/1)
      |> Enum.map(fn {:ok, post} -> post end)

    # 2. 更新 meta_registry
    new_meta_registry =
      updated_posts
      |> Map.new(fn p -> {p.id, p} end)
      |> Map.merge(meta_registry)

    # 3. 找出所有受影响的文章（直接修改的 + 引用了变化bib的）
    # posts_to_rebuild = find_affected_posts(updated_posts, bib_paths, new_meta_registry)

    # 4. 调用 Builder 进行部分构建
    # Builder.build_from_posts(posts_to_rebuild, {:partial, {new_meta_registry, index_registry}})
    # ...

    # 临时返回更新后的上下文
    {new_meta_registry, index_registry}
  end

  defp category_definitions(),
    do:
      Enum.map(
        [
          {:post, get_posts_root_path()},
          {:bib, get_bibliography_entry()},
          {:media, get_pic_entry()},
          {:media, get_pdf_entry()},
          {:media, get_dot_entry()}
        ],
        fn {k, path} -> {k, normalize_path(path)} end
      )

  defp normalize_path(path) do
    normalized = path |> Path.expand()

    if :os.type() == {:win32, :nt} do
      Regex.replace(~r/^[A-Z]:/, String.replace(normalized, "\\", "/"), &String.downcase/1)
    else
      normalized
    end
  end
end
