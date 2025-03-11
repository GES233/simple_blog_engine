defmodule GES233.Blog.Watcher do
  alias GES233.Blog.{Builder, Post, Media}

  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
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
        watchers: %{posts: posts_watcher, assets: assets_watcher}
      }
    }
  end

  defp do_init() do
    Builder.build_from_root()
  end

  # FileSystem related

  def handle_info(
        {:file_event, _watcher_pid, {_path, _events} = got},
        %{watchers: %{posts: _posts_watcher, assets: _assets_watcher}, meta: {_meta, _index}} = s
      ) do
    IO.inspect(got, label: :event)

    # 将命令改为操作，在特定的事件窗口（e.g. 2000ms无更新）执行更新

    # {:noreply, %{watchers: %{posts: posts_watcher, assets: assets_watcher}, meta: new_meta}}
    {:noreply, s}
  end

  def do_update(diff_paths, {meta, index}, :update) do
    # update 操作包含一个隐藏的前提：没有在 meta 里的都是 bibliography
    ids =
      Enum.map(
        diff_paths,
        &(&1
          |> Path.basename()
          |> :binary.split(".")
          |> hd())
      )

    maybe_bib =
      ids
      |> Enum.reject(&(&1 in Map.keys(meta)))

    posts_within_bib =
      if length(maybe_bib) >= 1 do
        meta
        |> Enum.filter(fn {_, p} -> is_struct(p, Post) end)
        |> Enum.map(fn {_, v} -> v end)
        |> Enum.filter(&(!is_nil(Map.get(&1.extra, "pandoc"))))
        |> Enum.filter(&(!is_nil(Map.get(&1.extra["pandoc"], "bibliography"))))
        |> Enum.filter(&(&1.extra["pandoc"]["bibliography"] in maybe_bib))
      else
        []
      end

    posts =
      Enum.filter(meta, fn {k, _} -> k in ids end)
      |> Enum.filter(fn {_, v} -> is_struct(v, Post) end)
      |> Keyword.keys()

    # If Media

    maybe_media =
      Enum.filter(meta, fn {k, _} -> k in ids end)
      |> Enum.filter(fn {_, v} -> is_struct(v, Media) end)
      |> Keyword.keys()

    media_validator = maybe_media |> Enum.map(&"#{&1}.")

    meta =
      diff_paths
      |> Enum.filter(&String.contains?(&1, media_validator))
      |> Enum.map(&Media.parse_media/1)
      |> Enum.map(fn m -> {m.id, m} end)
      |> Enum.into(%{})
      |> then(&Map.merge(meta, &1))

    diff_paths
    |> Enum.filter(&String.contains?(&1, posts_within_bib ++ posts))
    |> Enum.map(&Post.path_to_struct/1)
    |> Builder.build_from_posts({:partial, {meta, index}})
  end

  def do_update(created_paths, {_meta, _index}, :create) do
    # Is path under `Application.get_env(:ges233, :blog_root)` ?
    _maybe_posts =
      Enum.filter(created_paths, &String.contains?(&1, Application.get_env(:ges233, :blog_root)))

    _maybe_bib =
      Enum.filter(
        created_paths,
        &String.contains?(&1, Application.get_env(:ges233, :bibliography_entry))
      )

    _maybe_media = []
  end

  def update_bib(bib_paths, meta) do
    bib_paths
    |> List.wrap()
    |> Enum.filter(&String.contains?(&1, Application.get_env(:ges233, :bibliography_entry)))

    if length(bib_paths) >= 1 do
      meta
      |> Enum.filter(fn {_, p} -> is_struct(p, Post) end)
      |> Enum.map(fn {_, v} -> v end)
      |> Enum.filter(&(!is_nil(Map.get(&1.extra, "pandoc"))))
      |> Enum.filter(&(!is_nil(Map.get(&1.extra["pandoc"], "bibliography"))))
      |> Enum.filter(&(&1.extra["pandoc"]["bibliography"] in bib_paths))
    else
      []
    end
  end
end
