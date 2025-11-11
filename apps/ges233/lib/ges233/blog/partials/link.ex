defmodule GES233.Blog.Link do
  @moduledoc "形如 `:{inner_id}` => `inner_id_link`"

  require Logger
  alias GES233.Blog.{Post, Media}

  @raw_link_pattern ~r/:\{(\S+)\}/

  def page_convert(match, meta) do
    inner =
      Regex.run(@raw_link_pattern, match)
      |> Enum.at(1)

    case Map.get(meta, inner) do
      %Post{} ->
        Post.post_id_to_route(meta[inner])

      %Media{type: :dot} ->
        meta[inner].route_path ||
          """
          ```dot
          // Compile failed!
          #{meta[inner].inner_content}
          ```
          """

      %Media{type: :pdf} ->
        meta[inner].route_path |> GES233.Blog.Static.inject_when_pdf()

      %Media{type: :pic} ->
        meta[inner].route_path

      %Media{type: :lilypond} ->
        meta[inner].route_path ||
          """
          ```lilypond
          #{meta[inner].inner_content}
          ```
          """

      # like function defination in Julia
      # bla bla ::{DataFrame,Any}
      _ ->
        match
    end
  end

  def inner_replace(source, meta, func \\ &page_convert/2) do
    replaced = Regex.replace(@raw_link_pattern, source, fn match -> func.(match, meta) end)

    if String.contains?(replaced, "aspect-ratio") do
      {:replaced,
       """
       <style>
         /* Reference: https://www.webhek.com/post/responsive-video-iframes-keeping-aspect-ratio-with-only-css/ */
         /* 这个规则规定了iframe父元素容器的尺寸，我们要求它的宽高比应该是 25:14 */
         .aspect-ratio {
           position: relative;
           /* heti 的容器下允许使用 100% */
           width: 100%;
           height: 0;
           padding-bottom: 56%;
           /* 高度应该是宽度的56% */
         }

         /* 设定iframe的宽度和高度，让iframe占满整个父元素容器 */
         .aspect-ratio iframe {
           position: absolute;
           width: 100%;
           height: 100%;
           left: 0;
           top: 0;
         }
       </style>
       #{replaced}
       """}
    else
      {nil, replaced}
    end
  end
end
