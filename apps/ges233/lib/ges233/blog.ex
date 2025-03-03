defmodule GES233.Blog do
  alias GES233.Blog.{Post, Parser}

  @default_rootpath File.cwd!() |> Path.join("priv/_posts")

  defmodule Parser do
    def parse(_path, contents) do
      with %{} = meta <- Post.get_post_meta(contents),
           content <- Post.get_post_content(contents) do
        {:ok, meta, content}
      else
        err -> {:error, err}
      end
    end
  end

  use NimblePublisher,
    build: Post,
    from: @default_rootpath <> "/**/*.md",
    as: :posts,
    highlighters: [:makeup_elixir],
    parser_module: Parser,
    html_converter: GES233.Blog.Renderer

  def get_posts_from_root(root) do
    Path.wildcard(root <> "/**/*.md")
    |> Enum.reduce([], fn path, prev -> [GES233.Blog.Post.build(path) | prev] end)
    |> Enum.filter(fn {k, _v} -> k == :ok end)
    |> Enum.map(fn {_, v} -> v end)
  end

  # 整体流程：
  # 将文件系统上的内容变为 [%Post{}]
  # 确定内容组织的形式（~sigil_p like）
  #   用 Regex 替代
  # -> 确定内容组织的形式（tags, categories, serires, date）
  # -> 渲染博客内容的页面
  # => 渲染索引页面
end
