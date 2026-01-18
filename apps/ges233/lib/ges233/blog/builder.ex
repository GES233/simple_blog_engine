defmodule GES233.Blog.Builder do
  require Logger

  alias GES233.Blog.{
    Post,
    Static,
    Context,
    Writer
  }

  alias GES233.Blog.Post.RegistryBuilder
  import RegistryBuilder, only: [get_posts_root_path: 0]

  @spec get_posts(binary()) :: [Post.t(), ...]
  def get_posts(root) do
    do_fetch_posts(root)
    |> Enum.reduce([], fn {:ok, res}, prev -> [res | prev] end)
  end

  defp do_fetch_posts(root) do
    Path.wildcard(root <> "/**/*.md")
    |> Task.async_stream(&Post.path_to_struct/1)
  end

  # Elapse
  # {elapse, _} = :timer.tc(&GES233.Blog.Builder.build_from_root/0); elapse
  # Not accurate
  # 5879091 (Only VSCode)
  # 6867661(VSCode and Browser opened)
  @spec build_from_root() :: Context.t()
  def build_from_root(root_path \\ get_posts_root_path()) do
    # 将文件系统上的内容变为 [%Post{}]

    root_path
    |> get_posts()
    |> build_from_posts(:whole)
  end

  @spec build_from_posts([Post.t()], :whole | {:partial, Context.t()}) :: Context.t()
  def build_from_posts(posts, :whole) do
    # 2. 装载多媒体、Bib 等内容
    posts
    |> RegistryBuilder.get_meta_registry()
    |> render_posts(posts)
    |> Writer.copy_users_assets()
    |> do_build_posts
  end

  def build_from_posts([], {:partial, context}) do
    context
  end

  def build_from_posts(diff_posts, {:partial, {meta_registry, _}}) do
    meta_registry
    |> render_posts(diff_posts)
    |> Writer.copy_users_assets()
    |> do_build_posts()
  end

  defp do_build_posts(meta_registry) do
    Static.copy_static()

    index_registry = RegistryBuilder.get_index_registry(meta_registry)

    {meta_registry, index_registry}
    |> Writer.write_index()
    |> Writer.write_standalone_pages()
  end

  # 需要重构
  defp render_posts(meta_registry, posts) do
    render_posts =
      posts
      # 将 %Posts{} 正文的链接替换为实际链接 & 调用 Pandoc 渲染为 HTML
      |> Task.async_stream(
        &Post.add_html(&1, meta_registry),
        max_concurrency: System.schedulers_online(),
        timeout: 10000
      )
      |> Enum.map(fn {:ok, post} -> post end)

    # |> Enum.map(fn post -> IO.inspect(post.doc); post end)
    # Max: 1569587μs
    # 渲染文章网页的外观

    bodies_with_id_and_toc =
      render_posts
      |> Enum.map(fn post ->
        doc = post.doc
        {post.id,
         {post.toc,
          """
          #{doc.body}
          #{if(!is_nil(doc.footnotes), do: doc.footnotes, else: "")}
          #{if(!is_nil(doc.bibliography), do: doc.bibliography, else: "")}
          """}}
      end)

    # 保存在特定目录
    bodies_with_id_and_toc
    |> Task.async_stream(&save_post(&1, meta_registry),
      max_concurrency: System.schedulers_online()
    )
    |> Stream.run()

    has_abstract =
      render_posts
      |> Enum.filter(&is_struct(&1.doc, Pandox.Doc))
      |> Enum.reject(&is_nil(&1.doc.summary))
      |> Enum.map(fn p -> {p.id, p} end)
      |> Enum.into(%{})

    Map.merge(meta_registry, has_abstract)
  end

  def save_post({id, {toc, body}}, meta_registry) do
    %{meta_registry[id] | toc: toc}
    |> Writer.SinglePage.write_post_html(
      body,
      meta_registry
    )
  end
end
