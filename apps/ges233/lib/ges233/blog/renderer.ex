defmodule GES233.Blog.Renderer do
  def convert(path, body, meta, opts) do
    case Path.extname(path) do
      ".md" -> convert_mardown(body, meta, opts)
      _ -> body
    end
  end

  def convert_mardown(body, meta, _opts) do
    body
    |> link_replace()
    # 先过一遍 Pandox
    |> Pandox.render_markdown_to_html(meta)

    # 再过一遍 PhoenixHTML
  end

  defp link_replace({:ref, id}) do
    id

    # 这块儿得改成文字本身
    # 把本体丢给 pandoc 再得到 HTML
  end

  defp link_replace(pre) when is_binary(pre) do
    # Get meta from Registry
    # Wrap the logics into func/1

    GES233.Blog.Link.inner_replace(pre)
  end
end
