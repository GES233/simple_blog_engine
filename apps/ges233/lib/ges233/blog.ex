defmodule GES233.Blog do
  # 整体流程：
  # 将文件系统上的内容变为 [%Post{}]
  # 确定内容组织的形式（~sigil_p like）
  #   用 Regex 替代
  # -> 确定内容组织的形式（tags, categories, serires, date）
  # -> 渲染博客内容的页面
  # => 渲染索引页面

  @default_rootpath Application.compile_env(:ges233, :blog_root, File.cwd!() |> Path.join("priv/_posts"))

  # Without nimble_publisher
  @spec get_posts_from_root(binary()) :: [GES233.Blog.Post.t(), ...]
  def get_posts_from_root(root \\ @default_rootpath) do
    Path.wildcard(root <> "/**/*.md")
    |> Task.async_stream(fn path ->
      path |> GES233.Blog.Post.path_to_struct() |> GES233.Blog.Post.add_html_without_nimble()
    end)
    |> Enum.reduce([], fn {:ok, res}, prev -> [res | prev] end)
  end
end
