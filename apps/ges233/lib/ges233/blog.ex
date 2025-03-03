defmodule GES233.Blog do
  # Compiling lib/ges233/blog.ex (it's taking more than 10s)
  alias GES233.Blog.{Post, Parser}

  @default_rootpath File.cwd!() |> Path.join("priv/_posts")

  defmodule Parser do
    def parse(_path, contents) do
      with %{} = meta <- Post.get_post_meta(contents),
           content <- Post.get_post_content(contents) do
        {meta, content}
      end
    end
  end

  use NimblePublisher,
    build: Post,
    from: Application.compile_env(:ges233, :blog_root, @default_rootpath) <> "/**/*.md",
    as: :posts,
    highlighters: [:makeup_elixir],
    parser: Parser,
    html_converter: GES233.Blog.Renderer

  @spec get_posts_from_root(binary()) :: [GES233.Blog.Post.t(), ...]
  def get_posts_from_root(root) do
    Path.wildcard(root <> "/**/*.md")
    |> Enum.reduce([], fn path, prev -> [GES233.Blog.Post.path_to_struct(path) | prev] end)
    |> Enum.filter(fn {k, _v} -> k == :ok end)
    |> Enum.map(fn {_, v} -> v end)
  end

  @posts Enum.sort_by(@posts, &(&1.create_at), {:desc, NaiveDateTime})

  @spec posts() :: [GES233.Blog.Post.t(), ...]
  def posts, do: @posts

  @tags GES233.Blog.Tags.fetch_all_tags_from_posts(@posts)

  @spec tags :: [binary()]
  def tags, do: @tags

  # 整体流程：
  # 将文件系统上的内容变为 [%Post{}]
  # 确定内容组织的形式（~sigil_p like）
  #   用 Regex 替代
  # -> 确定内容组织的形式（tags, categories, serires, date）
  # -> 渲染博客内容的页面
  # => 渲染索引页面
end
