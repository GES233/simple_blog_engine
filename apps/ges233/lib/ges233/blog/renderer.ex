defmodule GES233.Blog.Renderer do
  def convert(path, body, meta, opts) do
    case Path.extname(path) do
      ".md" -> convert_mardown(body, meta, opts)
      _ -> nil
    end
  end

  defp convert_mardown(body, meta, _opts) do
    # 先过一遍 Pandox
    # 再过一遍 PhoenixHTML
    body
    |> Pandox.render_markdown_to_html(meta)
  end
end
