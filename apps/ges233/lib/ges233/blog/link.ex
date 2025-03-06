defmodule GES233.Blog.Link do
  @moduledoc "形如 `:{inner_id}` => `inner_id_link`"

  require Logger
  alias GES233.Blog.Post

  @raw_link_pattern ~r/:\{(w+)\}/

  ## 内容
  # 博客

  # 图片
  # image/SEIRES/ID
  # def pic_to_route

  # DOT
  # PDF

  # AIO
  def page_convert(match, meta) do
    Post.post_id_to_route(meta[match])
  end

  def inner_replace(source, meta, func \\ &page_convert/2) do
    Regex.replace(@raw_link_pattern, source, fn match -> func.(match, meta) end)
  end
end
