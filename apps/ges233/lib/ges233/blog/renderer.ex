defmodule GES233.Blog.Renderer do
  def convert(_path, _body, _meta, _opts), do: nil
  # 先过一遍 Pandox
  # 再过一遍 PhoenixHTML
end
