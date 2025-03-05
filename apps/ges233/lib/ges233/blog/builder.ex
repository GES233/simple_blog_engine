defmodule GES233.Blog.Builder do
  alias GES233.Blog.{Post, Tags, Series}

  @default_rootpath Application.compile_env(
                      :ges233,
                      :blog_root,
                      File.cwd!() |> Path.join("priv/_posts")
                    )

  @spec get_posts(binary()) :: [Post.t(), ...]
  def get_posts(root) do
    Path.wildcard(root <> "/**/*.md")
    |> Task.async_stream(&Post.path_to_struct/1)
    # TODO: 可以改成装载到某 Registry 里
    |> Enum.reduce([], fn {:ok, res}, prev -> [res | prev] end)
  end

  # 博客的重构：
  # - [x] Bib
  # - [ ] Series
  # - [x] Tags
  # - [ ] Categories
  # - [ ] HTML
  def build(root_path \\ @default_rootpath) do
  # 1. 将文件系统上的内容变为 [%Post{}]
  posts = get_posts(root_path)

  # 2. 将内容建立索引
  # via tags, categories, serires, date
  # id => link on server
  _tags_frq = Tags.get_tags_frq_from_posts(posts)
  _series = Series.fetch_all_series_from_posts(posts)
  _sorted_posts = Enum.sort_by(posts, &(&1.create_at), {:desc, NaiveDateTime})

  # 3. 装载多媒体、Bib 等内容
  # 依旧 id => link on server

  # 4. 将 %Posts{} 正文的链接替换为实际链接
  # 5. 调用 Pandoc 渲染为 HTML
  _posts = posts
  |> Enum.map(&Task.async(fn -> Post.add_html(&1) end))
  |> Enum.map(&Task.await/1)

  # 6. 渲染外观以及其他界面
  # 7. 保存在特定目录

  :ok
  end
end
