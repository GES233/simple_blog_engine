defmodule GES233.Blog.Renderer do
alias GES233.Blog.{Post, Bibliography}

  def convert_markdown(post = %Post{}, _opts) do
    body = link_replace(post.content)

    {_, meta} = {post, %{}}
    |> Bibliography.maybe_validate_bibliography_exist()
    |> Bibliography.ensure_bib_format()

    meta = if Map.get(meta, "bibliography") do
      meta
    else
      %{}
    end

    # 先过一遍 Pandox
    Pandox.render_markdown_to_html(body, meta)
    # 再过一遍 PhoenixHTML
  end

  defp link_replace({:ref, id}) do
    {:ok, raw} = Post.ContentRepo.get_raw(id)

    # 这块儿得改成文字本身
    # 把本体丢给 pandoc 再得到 HTML
    link_replace(raw)
  end

  defp link_replace(pre) when is_binary(pre) do
    # Get meta from Registry
    # Wrap the logics into func/1

    GES233.Blog.Link.inner_replace(pre)
  end
end
