defmodule GES233.Blog.Builder do
  require Logger
  alias GES233.Blog.Post.ContentRepo
  alias GES233.Blog.Post.RegistryBuilder
  alias GES233.Blog.{Post, Tags, Series, Renderer}

  @default_rootpath Application.compile_env(
                      :ges233,
                      :blog_root,
                      File.cwd!() |> Path.join("priv/_posts")
                    )

  @pic_entry Application.compile_env(:ges233, [:Media, :pic_path])
  @pdf_entry Application.compile_env(:ges233, [:Media, :pdf_path])
  @dot_entry Application.compile_env(:ges233, [:Media, :dot_path])

  @spec get_posts(binary()) :: [Post.t(), ...]
  def get_posts(root) do
    do_fetch_posts(root)
    |> Enum.reduce([], fn {:ok, res}, prev -> [res | prev] end)
  end

  # def load_posts(root) do
  #   do_fetch_posts(root)
  # end

  defp do_fetch_posts(root) do
    Path.wildcard(root <> "/**/*.md")
    |> Task.async_stream(&Post.path_to_struct/1)
  end

  def build_from_root(root_path \\ @default_rootpath) do
    # 1. 将文件系统上的内容变为 [%Post{}]

    root_path
    |> get_posts()
    |> build_from_posts(:whole)
  end

  # Only for test
  def build_single_post(post_id \\ "2022-Pig-sensor") do
    [
      "#{@default_rootpath}/#{post_id}.md"
      |> Post.path_to_struct()
    ]
    |> build_from_posts(:whole)
    |> Enum.at(0)
    |> then(&File.write("demo.html", &1))
  end

  # 博客的重构：
  # - [x] Bib
  # - [x] Series
  # - [x] Tags
  # - [ ] Categories
  # - [x] HTML
  # Elapse
  # :timer.tc(&GES233.Blog.Builder.build_from_root/0)
  # {6075904, :ok}
  # {6167654, :ok}
  # {11537203, :ok}  # Add media related
  # {13074227, :ok}  # Remove Task
  # {2822348, :ok}
  def build_from_posts(posts, :whole) do
    # 2. 将内容建立索引
    # via tags, categories, serires, date
    _tags_frq = Tags.get_tags_frq_from_posts(posts)
    _categories = []
    _series = Series.fetch_all_series_from_posts(posts)

    # 3. 装载多媒体、Bib 等内容
    # 依旧 id => link on server
    # 需要将多媒体内容注入到 %Post{} 之中
    # 可能还需要博客的一些信息
    meta_registry =
      ((RegistryBuilder.build_posts_registry(posts) ++
          RegistryBuilder.build_media_registry(@pic_entry, :pic) ++
          RegistryBuilder.build_media_registry(@pdf_entry, :pdf) ++
          RegistryBuilder.build_media_registry(@dot_entry, :dot)) ++
         [])
      |> Enum.into(%{})

    ## Common process

    bodies_with_id =
      posts
      # 4. 将 %Posts{} 正文的链接替换为实际链接
      # 5. 调用 Pandoc 渲染为 HTML
      |> Enum.map(&Task.async(fn -> Post.add_html(&1, meta_registry) end))
      |> Enum.map(&Task.await(&1, 20000))
      # Max: 1569587μs
      # 6. 渲染外观以及其他界面
      |> Enum.map(fn post ->
        {status, html} = ContentRepo.get_html(post.id)

        new_body =
          case status do
            :ok ->
              html

            :error ->
              post.body
          end

        # %{post | body: new_body}
        {post.id, new_body}
      end)

    # 7. 保存在特定目录
    bodies_with_id
    |> Enum.map(fn {id, body} ->
      p = meta_registry[id]

      # Recursively created path.
      File.mkdir_p("#{Application.get_env(:ges233, :saved_path)}/#{Post.post_id_to_route(p)}")

      File.write(
        "#{Application.get_env(:ges233, :saved_path)}/#{Post.post_id_to_route(p)}/inhex.html",
        body |> Renderer.add_article_layout(p, meta_registry)
      )
    end)

    # 8. 把 <!--more--> 之前的部分拿出来
    meta_registry = bodies_with_id
    |> Enum.filter(fn {_id, body} -> String.contains?(body, "<!--more-->") end)
    |> Enum.map(fn {id, body} ->
      {id, %{meta_registry[id] | body: String.split(body, "<!--more-->", parts: 2) |> Enum.at(0)}}
    end) |> Enum.into(%{})
    |> then(&Map.merge(meta_registry, &1))

    _sorted_posts =
      meta_registry
      |> Enum.filter(&is_struct(&1, Post))
      |> Enum.map(&Task.await/1)
      |> Enum.sort_by(& &1.create_at, {:desc, NaiveDateTime})

    {:ok, meta_registry}
  end

  # def build_from_posts(diff_posts, {:partial, meta}) do

  # def build_index

  # def save_post

  # def save_pic

  # def save_file
end
