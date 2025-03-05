defmodule GES233.Blog.Renderer do
alias GES233.Blog.{Post, Bibliography}

  def convert_markdown(post = %Post{}, opts) do
    all_posts_and_media = Keyword.get(opts, :meta)
    body = link_replace(post, all_posts_and_media)

    {post, %{}}
    |> Bibliography.maybe_validate_bibliography_exist()
    |> Bibliography.ensure_bib_format()
    |> Bibliography.postlude()
    # 先过一遍 Pandox
    |> then(&Pandox.render_markdown_to_html(body, &1))
    # 再过一遍 PhoenixHTML
  end

  defp link_replace(%Post{content: {:ref, id}}, posts_and_mata) do
    {:ok, raw} = Post.ContentRepo.get_raw(id)

    # 这块儿得改成文字本身
    # 把本体丢给 pandoc 再得到 HTML
    GES233.Blog.Link.inner_replace(raw, posts_and_mata)
  end

  defp link_replace(%Post{content: pre}, posts_and_mata) when is_binary(pre) do
    GES233.Blog.Link.inner_replace(pre, posts_and_mata)
  end
end
