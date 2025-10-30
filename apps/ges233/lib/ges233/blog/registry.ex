defmodule GES233.Blog.Post.RegistryBuilder do
  alias GES233.Blog.{Post, Media, Context, Tags, Categories, Series, Page}

  @default_rootpath Application.compile_env(
                      :ges233,
                      :blog_root,
                      "priv/_posts"
                    )
  @pic_entry Application.compile_env(:ges233, [:Media, :pic_path])
  @pdf_entry Application.compile_env(:ges233, [:Media, :pdf_path])
  @dot_entry Application.compile_env(:ges233, [:Media, :dot_path])

  @type post_registry :: %{atom() => Post.t()}

  def build_posts_registry(posts) do
    posts
    |> Enum.map(&Task.async(fn -> remove_raw_and_html(&1) end))
    |> Enum.map(&Task.await(&1, 10000))
    |> Enum.map(fn post -> {post.id, post} end)

    # |> Enum.into(%{})
  end

  def build_media_registry(root_path, format) do
    cond do
      format in [:pic, :pdf, :dot] ->
        Media.get_media_under(root_path, format)
        |> Enum.map(fn m -> {m.id, m} end)

      true ->
        nil
    end

    # Load to registry with type
  end

  defp remove_raw_and_html(post = %Post{}) do
    %{post | content: nil, body: nil}
  end

  @spec get_meta_registry([Post.t()]) :: Context.meta_registry()
  def get_meta_registry(posts) do
    ((build_posts_registry(posts) ++
        build_media_registry(@pic_entry, :pic) ++
        build_media_registry(@pdf_entry, :pdf) ++
        build_media_registry(@dot_entry, :dot)) ++
       [])
    |> Enum.into(%{})
  end

  @spec build_meta_from_root(binary()) :: %{binary() => Post.t() | Media.t()}
  def build_meta_from_root(root \\ @default_rootpath) do
    posts =
      Path.wildcard(root <> "/**/*.md")
      |> Task.async_stream(&Post.path_to_struct/1)
      |> Enum.reduce([], fn {:ok, res}, acc -> [res | acc] end)
      |> Enum.map(&Task.async(fn -> remove_raw_and_html(&1) end))
      |> Enum.map(&Task.await(&1, 10000))

    posts_registry =
      posts
      |> Enum.map(&{&1.id, &1})

    media_registry =
      build_media_registry(@pic_entry, :pic) ++
        build_media_registry(@pdf_entry, :pdf) ++
        build_media_registry(@dot_entry, :dot) ++ []

    (posts_registry ++ media_registry)
    |> Enum.into(%{})
  end

  @spec get_index_registry(Context.meta_registry()) :: Context.index_registry()
  def get_index_registry(meta_registry) do
    posts =
      meta_registry
      |> Enum.filter(fn {_, p} -> is_struct(p, Post) end)
      |> Enum.map(fn {_, v} -> v end)

    # via tags, categories, serires, date
    %{
      "tags-with-frequrent" => Tags.get_tags_frq_from_posts(posts),
      "categories" => Categories.build_category_tree(posts),
      "series" => Series.fetch_all_series_from_posts(posts),
      "single_pages" => Page.all_in_one(meta_registry)
    }
  end
end
