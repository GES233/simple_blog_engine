defmodule GES233.Blog.Builder do
  require Logger

  alias GES233.Blog.{
    Post,
    Static,
    ContentRepo,
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

  # Only for test
  def build_single_post(post_id \\ "World-execute-me-lyrics-analyse", context \\ [])

  def build_single_post(post_id, []) do
    [
      "#{get_posts_root_path()}/#{post_id}.md"
      |> Post.path_to_struct()
    ]
    |> build_from_posts(:whole)
  end

  def build_single_post(post_id, context) do
    [
      "#{get_posts_root_path()}/#{post_id}.md"
      |> Post.path_to_struct()
    ]
    |> build_from_posts({:partial, context})
  end

  @spec build_from_posts([Post.t()], :whole | {:partial, Context.t()}) :: Context.t()
  def build_from_posts(posts, :whole) do
    # 2. 装载多媒体、Bib 等内容
    meta_registry =
      posts
      |> RegistryBuilder.get_meta_registry()
      |> render_posts(posts)
      |> Writer.copy_users_assets()

    Static.copy_static()

    index_registry = RegistryBuilder.get_index_registry(meta_registry)

    {meta_registry, index_registry}
    |> Writer.write_index()
    |> Writer.write_standalone_pages()
  end

  def build_from_posts(diff_posts, {:partial, {meta_registry, _}}) do
    updated_meta =
      meta_registry
      |> render_posts(diff_posts)
      |> Writer.copy_users_assets()

    Static.copy_static()

    index_registry = RegistryBuilder.get_index_registry(updated_meta)

    {updated_meta, index_registry}
    |> Writer.write_index()
    |> Writer.write_standalone_pages()
  end

  defp render_posts(meta_registry, posts) do
    bodies_with_id_and_toc =
      posts
      # 将 %Posts{} 正文的链接替换为实际链接 & 调用 Pandoc 渲染为 HTML
      |> Task.async_stream(
        &Post.add_html(&1, meta_registry),
        max_concurrency: System.schedulers_online()
      )
      |> Enum.map(fn {:ok, post} -> post end)
      # Max: 1569587μs
      # 渲染文章网页的外观
      |> Enum.map(fn post ->
        {post.id, {post.toc, get_body_from_post(post)}}
      end)

    # 保存在特定目录
    bodies_with_id_and_toc
    |> Task.async_stream(&save_post(&1, meta_registry),
      max_concurrency: System.schedulers_online()
    )
    |> Stream.run()

    # 把 <!--more--> 之前的部分拿出来

    has_abstract =
      bodies_with_id_and_toc
      |> Enum.filter(fn {_id, {_, body}} -> String.contains?(body, "<!--more-->") end)
      |> Enum.map(fn {id, {_, body}} ->
        {id,
         %{meta_registry[id] | body: String.split(body, "<!--more-->", parts: 2) |> Enum.at(0)}}
      end)
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

  defp get_body_from_post(post) do
    {status, html} = ContentRepo.get_html(post.id)

    case status do
      :ok ->
        html

      :error ->
        post.body
    end
  end
end
