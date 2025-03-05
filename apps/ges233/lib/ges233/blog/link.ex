defmodule GES233.Blog.Link do
  @moduledoc "形如 `:{inner_id}` => `[inner_id](inner_id_link)`"
  require Logger
  # 链接相关

  @raw_link_pattern ~r/:\{(w+)\}/

  ## 内容
  # 博客
  def id_to_route(id, meta) do
    if id in Map.keys(meta) do
      _post = meta[id]
    else
      Logger.warning("")
    end
  end

  # 图片
  # def pic_to_route

  # DOT
  # PDF

  # AIO
  def page_convert(match, _meta) do
    match
    # cond => 一堆 Regex.replace
    # 如果都没有 match 的话就
  end

  def inner_replace(source, meta, func \\ &page_convert/2) do
    Regex.replace(@raw_link_pattern, source, fn match -> func.(match, meta) end)
  end
end
