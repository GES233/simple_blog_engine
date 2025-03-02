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
    |> PandocRenderer.render_markdown_to_html(meta)
  end
end

# Generated from Deepseek
defmodule PandocRenderer do
  @pandoc_flags ~w(
    --mathjax
    -f markdown+smart+emoji
    -t html
  )
  # --filter=pandoc-crossref --citeproc --bibliography=references.bib

  def render_markdown_to_html(content, metadata_to_pandoc) do
    # 生成临时文件
    input_file = Path.join(System.tmp_dir!(), "input_#{System.unique_integer()}.md")
    output_file = Path.join(System.tmp_dir!(), "output_#{System.unique_integer()}.html")

    # 写入内容（包含元数据）
    File.write!(input_file, build_front_matter(metadata_to_pandoc) <> "\n" <> content)

    # 调用 Pandoc
    res = System.cmd("pandoc", args(input_file, output_file), stderr_to_stdout: true)
    |> handle_result(output_file)

    File.rm(input_file)
    File.rm(output_file)

    res
  end

  defp args(input, output) do
    @pandoc_flags ++ [input, "-o", output]
  end

  defp build_front_matter(metadata) do
    """
    ---
    #{inspect(metadata)}
    ---
    """
  end

  defp handle_result({_, 0}, output_file) do
    File.read!(output_file)
  end

  defp handle_result({code, msg}, _) do
    raise "Pandoc failed with code #{code}: #{msg}"
  end
end
