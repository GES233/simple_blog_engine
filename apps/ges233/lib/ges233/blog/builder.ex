defmodule GES233.Blog.Builder do
  require Logger

  alias GES233.Blog.{
    Post,
    Renderer,
    Media,
    Static,
    Page,
    ContentRepo,
    Context,
    Writer
  }

  alias GES233.Blog.Post.RegistryBuilder

  @default_rootpath Application.compile_env(
                      :ges233,
                      :blog_root,
                      "priv/_posts"
                    )

  @page_pagination Application.compile_env(:ges233, [:Blog, :page_pagination])

  @spec get_posts(binary()) :: [Post.t(), ...]
  def get_posts(root) do
    do_fetch_posts(root)
    |> Enum.reduce([], fn {:ok, res}, prev -> [res | prev] end)
  end

  defp do_fetch_posts(root) do
    Path.wildcard(root <> "/**/*.md")
    |> Task.async_stream(&Post.path_to_struct/1)
  end

  def build_from_root(root_path \\ @default_rootpath) do
    # 将文件系统上的内容变为 [%Post{}]

    root_path
    |> get_posts()
    |> build_from_posts(:whole)
  end

  # Only for test
  def build_single_post(post_id \\ "World-execute-me-lyrics-analyse") do
    [
      "#{@default_rootpath}/#{post_id}.md"
      |> Post.path_to_struct()
    ]
    |> build_from_posts(:whole)
  end

  # Elapse
  # {elapse, _} = :timer.tc(&GES233.Blog.Builder.build_from_root/0); elapse
  # Not accurate
  # 5879091 (Only VSCode)
  # 6867661(VSCode and Browser opened)
  @spec build_from_posts([Post.t()], :whole | {:partial, Context.t()}) :: Context.t()
  def build_from_posts(posts, :whole) do
    # 2. 装载多媒体、Bib 等内容
    meta_registry =
      posts
      |> RegistryBuilder.get_meta_registry()
      |> render_posts(posts)
      |> copy_users_assets()

    Static.copy_static()

    index_registry = RegistryBuilder.get_index_registry(meta_registry)

    {meta_registry, index_registry}
    |> build_index()
    |> build_pages()
  end

  def build_from_posts(diff_posts, {:partial, {meta_registry, _}}) do
    updated_meta =
      meta_registry
      |> render_posts(diff_posts)
      |> copy_users_assets()

    Static.copy_static()

    index_registry = RegistryBuilder.get_index_registry(updated_meta)

    {updated_meta, index_registry}
    |> build_index()
    |> build_pages()
  end

  @spec build_index(Context.t()) :: Context.t()
  def build_index({meta_registry, _index_registry} = context) do
    pages =
      meta_registry
      |> Enum.map(fn {_, v} -> v end)
      |> Enum.filter(&is_struct(&1, Post))
      |> Enum.sort_by(& &1.create_at, {:desc, NaiveDateTime})
      |> pagination([])

    pages
    |> length()
    |> then(&Range.new(1, &1))
    |> Enum.zip(pages)
    |> Task.async_stream(fn {index, page} -> Writer.write_index_page(index, page, pages) end,
      max_concurrency: System.schedulers_online()
    )
    |> Stream.run()

    context
  end

  @spec build_pages(Context.t()) :: Context.t()
  def build_pages({_meta_registry, %{"single_pages" => pages}} = context) do
    Task.async_stream(pages, fn page ->
      [
        Application.get_env(:ges233, :saved_path) |> Path.absname(),
        page.role |> Page.get_route_by_role(),
        "index.html"
      ]
      |> Path.join()
      |> Writer.write_single_page(
        Renderer.add_pages_layout(get_body_from_post_and_page(page, :role), page)
      )
    end)
    |> Stream.run()

    context
  end

  defp pagination(list, pages) when length(list) <= @page_pagination do
    [list | pages] |> :lists.reverse()
  end

  defp pagination(list, pages) do
    {page, rest} = Enum.split(list, @page_pagination)

    pagination(rest, [page | pages])
  end

  @spec copy_users_assets(Context.meta_registry()) :: Context.meta_registry()
  def copy_users_assets(meta_registry) do
    meta_registry
    |> Enum.map(fn {_, v} -> v end)
    # dot 生成的 svg 直接被别的函数解决了，不需要再 copy
    |> Enum.filter(&(is_struct(&1, Media) && &1.type in [:pic, :pdf]))
    |> Task.async_stream(&Writer.copy_media_asset/1)
    |> Stream.run()

    meta_registry
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
        {post.id, {post.toc, get_body_from_post_and_page(post, :id)}}
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
    meta_registry[id]
    |> Writer.write_post_html(
      body |> Renderer.add_article_layout(%{meta_registry[id] | toc: toc}, meta_registry),
      meta_registry
    )
  end

  defp get_body_from_post_and_page(page_or_post, key) do
    {status, html} = ContentRepo.get_html(Map.get(page_or_post, key))

    case status do
      :ok ->
        html

      :error ->
        page_or_post.body
    end
  end
end
