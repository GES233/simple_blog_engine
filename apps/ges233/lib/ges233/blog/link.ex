defmodule GES233.Blog.Link do
  # 链接相关

  @raw_link_pattern ~r/:\{(w+)\}/

  ## 内容
  # 博客
  # 多媒体

  def inner_replace(source, func \\ &IO.inspect/1) do
    Regex.replace(@raw_link_pattern, source, fn match -> func.(match) end)
  end
end
