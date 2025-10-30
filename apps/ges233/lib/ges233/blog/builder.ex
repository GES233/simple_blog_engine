defmodule GES233.Blog.Builder do
  require Logger
  alias GES233.Blog.{Post, Tags, Series, Renderer, Media, Static, Categories, Page, ContentRepo, Context}
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
  # :timer.tc(&GES233.Blog.Builder.build_from_root/0)
  # {6075904, :ok}
  # {6167654, :ok}
  # {11537203, :ok}  # Add media related
  # {13074227, :ok}  # Remove Task
  # {2822348, :ok}
  @spec build_from_posts([Post.t()], :whole | {:partial, Context.t()}) :: Context.t()
  def build_from_posts(posts, :whole) do
    # 2. 装载多媒体、Bib 等内容
    meta_registry =
      posts
      |> RegistryBuilder.get_meta_registry()
      |> render_posts(posts)
      |> copy_users_assets()

    Static.copy_static()

    index_registry = get_index_registry(meta_registry)

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

    index_registry = get_index_registry(updated_meta)

    {updated_meta, index_registry}
    |> build_index()
    |> build_pages()
  end

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

  def build_index({meta_registry, _index_registry} = context) do
    sorted_posts =
      meta_registry
      |> Enum.map(fn {_, v} -> v end)
      |> Enum.filter(&is_struct(&1, Post))
      |> Enum.sort_by(& &1.create_at, {:desc, NaiveDateTime})

    pages = pagination(sorted_posts, [])

    page_with_id =
      pages
      |> length()
      |> then(&Range.new(1, &1))
      |> Enum.zip(pages)

    for {index, page} <- page_with_id do
      case {index, page} do
        {1, index_page} ->
          File.write(
            "#{Application.get_env(:ges233, :saved_path)}/index.html",
            Renderer.add_index_layout(index_page, 1, length(pages))
          )

        {num, page} ->
          File.mkdir_p("#{Application.get_env(:ges233, :saved_path)}/page/#{num}/")

          File.write(
            "#{Application.get_env(:ges233, :saved_path)}/page/#{num}/index.html",
            Renderer.add_index_layout(page, num, length(pages))
          )
      end
    end

    context
  end

  def build_pages({_meta_registry, %{"single_pages" => pages}} = context) do
    opt = (fn page ->
        {status, html} = ContentRepo.get_html(page.role)

        new_body =
          case status do
            :ok ->
              html

            :error ->
              page.body
          end

        new_body
      end)

    for page <- pages do
      inner_html = opt.(page)
      path =
        ~w(#{Application.get_env(:ges233, :saved_path) |> Path.absname()} #{page.role |> Page.get_route_by_role()})
        |> Path.join()
      File.mkdir_p(path)

      File.write(~w(#{path} index.html) |> Path.join(), Renderer.add_pages_layout(inner_html, page))
    end

    context
  end

  defp pagination(list, pages) when length(list) <= @page_pagination do
    [list | pages] |> :lists.reverse()
  end

  defp pagination(list, pages) do
    {page, rest} = Enum.split(list, @page_pagination)

    pagination(rest, [page | pages])
  end

  def copy_users_assets(meta_registry) do
    meta_registry
    |> Enum.map(fn {_, v} -> v end)
    # dot 生成的 svg 直接被别的函数解决了，不需要再 copy
    |> Enum.filter(&(is_struct(&1, Media) && &1.type in [:pic, :pdf]))
    |> Enum.map(
      &Task.async(fn ->
        "#{Application.get_env(:ges233, :saved_path)}/#{&1.route_path}"
        |> Path.split()
        |> :lists.droplast()
        |> Path.join()
        |> File.mkdir_p()

        File.copy(&1.path, "#{Application.get_env(:ges233, :saved_path)}/#{&1.route_path}")
        |> case do
          {:ok, _} ->
            nil

          {:error, reason} ->
            Logger.warning(
              "File with id: #{&1.id} copied not successfully due to #{inspect(reason)}"
            )
        end
      end)
    )
    |> Enum.map(&Task.await/1)

    meta_registry
  end

  defp render_posts(meta_registry, posts) do
    bodies_with_id_and_toc =
      posts
      # 将 %Posts{} 正文的链接替换为实际链接 & 调用 Pandoc 渲染为 HTML
      |> Enum.map(&Task.async(fn -> Post.add_html(&1, meta_registry) end))
      |> Enum.map(&Task.await(&1, 20000))
      # Max: 1569587μs
      # 渲染文章网页的外观
      |> Enum.map(fn post ->
        {status, html} = ContentRepo.get_html(post.id)

        new_body =
          case status do
            :ok ->
              html

            :error ->
              post.body
          end

        {post.id, {post.toc, new_body}}
      end)

    # 保存在特定目录
    bodies_with_id_and_toc
    |> Enum.map(&Task.async(fn -> save_post(&1, meta_registry) end))
    |> Enum.map(&Task.await/1)

    # 把 <!--more--> 之前的部分拿出来

    has_abstract =
      bodies_with_id_and_toc
      |> Enum.filter(fn {_id, {_, body}} -> String.contains?(body, "<!--more-->") end)
      |> Enum.map(fn {id, {_, body}} ->
        {id,
         %{meta_registry[id] | body: String.split(body, "<!--more-->", parts: 2) |> Enum.at(0)}}
      end)
      |> Enum.into(%{})

    # 这种已经没什么作用了，但我觉得这段代码最好留着
    # 可能后期需要这种合并操作
    # has_toc =
    #   bodies_with_id_and_toc
    #   |> Enum.filter(fn {_id, {toc, _}} -> !is_nil(toc) end)
    #   |> Enum.map(fn {id, {toc, _}} -> {id, %{meta_registry[id] | toc: toc}} end)
    #   |> Enum.into(%{})

    # append_posts = for id <- Map.keys(has_abstract) ++ Map.keys(has_toc) do
    #   case {Map.get(has_abstract, id), Map.get(has_toc, id)} do
    #     {nil, only_toc} -> {id, only_toc}
    #     {only_abs, nil} -> {id, only_abs}
    #     {abs, toc} -> {id, %{abs | toc: toc.toc}}
    #   end
    # end |> Enum.into(%{})

    Map.merge(meta_registry, has_abstract)
  end

  def save_post({id, {toc, body}}, meta_registry) do
    p = %{meta_registry[id] | toc: toc}

    # Recursively created path.
    File.mkdir_p("#{Application.get_env(:ges233, :saved_path)}/#{Post.post_id_to_route(p)}")

    File.write(
      "#{Application.get_env(:ges233, :saved_path)}/#{Post.post_id_to_route(p)}/index.html",
      body |> Renderer.add_article_layout(p, meta_registry)
    )
    |> case do
      :ok ->
        nil

      {:error, reason} ->
        Logger.warning("Save not successed when saved post `#{id}` with #{inspect(reason)}")
    end
  end
end
