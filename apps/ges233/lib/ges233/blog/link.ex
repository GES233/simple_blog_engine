defmodule GES233.Blog.Link do
  @moduledoc "形如 `:{inner_id}` => `inner_id_link`"

  require Logger
  alias GES233.Blog.{Post, Media}

  @raw_link_pattern ~r/:\{(\S+)\}/

  ## 内容
  # 博客

  # 图片
  # image/SEIRES/ID
  # def pic_to_route

  # DOT
  # PDF

  # AIO
  def page_convert(match, meta) do
    inner =
      Regex.run(@raw_link_pattern, match)
      |> Enum.at(1)

    case Map.get(meta, inner) do
      %Post{} -> Post.post_id_to_route(meta[inner])

      %Media{type: :dot} -> meta[inner].route_path || """
      ```dot
      #{meta[inner].inner_content}
      ```
      """

      %Media{type: :pdf} -> meta[inner].route_path |> GES233.Blog.Static.inject_when_pdf()

      %Media{type: :pic} -> meta[inner].route_path

      # like function defination in Julia
      # bla bla ::{DataFrame,Any}
      _ -> match
    end
  end

  def inner_replace(source, meta, func \\ &page_convert/2) do
    Regex.replace(@raw_link_pattern, source, fn match -> func.(match, meta) end)
  end
end
