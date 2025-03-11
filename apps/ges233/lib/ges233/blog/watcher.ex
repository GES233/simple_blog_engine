defmodule GES233.Blog.Watcher do
  alias GES233.Blog.{Builder, Media, Post}

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
        {:file_event, watcher_pid, {path, _events}},
        %{watchers: %{posts: posts_watcher, assets: assets_watcher}, meta: {meta, index}}
      ) do
        new_meta = case watcher_pid do
      ^posts_watcher ->
        # Post => 渲染
        # Bib => 渲染 extra[:bibliography] 中有这个的 Posts
        id = path
        |> Path.basename()
        |> :binary.split(".")
        |> hd()

        if id in Map.keys(meta) do
          # Post
          Builder.build_from_posts(Post.path_to_struct(path), {:partial, {meta, index}})
        else
          # Bib
          posts =
            meta
            |> Enum.filter(fn {_, p} -> is_struct(p, Post) end)
            |> Enum.map(fn {_, v} -> v end)
            |> Enum.filter(&Map.get(&1.extra, "pandoc"))
            |> Enum.filter(&(&1.extra["pandoc"]["bibliography"] == id))

            Builder.build_from_posts(posts, {:partial, {meta, index}})
        end

      ^assets_watcher ->
        Media.parse_media(
          path
          |> :binary.split(".")
          |> hd(),
          path
          |> Path.basename()
          |> :binary.split(".")
          |> Enum.at(1)
          |> String.to_atom()
        )

        {meta, index}
    end

    {:noreply, %{watchers: %{posts: posts_watcher, assets: assets_watcher}, meta: new_meta}}
  end
end
