defmodule Pandox do
  @moduledoc """
  Documentation for `Pandox`.
  """

  # 默认的 pandoc 可执行文件的地址
  # （我假定你是通过 Scoop/apt/Homebrew 等方式安装的）
  @pandoc_executable_name "pandoc"

  def get_pandoc() do
    # 还要考虑从配置中读取可执行文件的地址的情况
    @pandoc_executable_name
  end

  def get_args_from_meta(%{"pandoc" => args}), do: do_extract_args(args)
  def get_args_from_meta(%{pandoc: args}), do: do_extract_args(args)
  def get_args_from_meta(_), do: []

  def do_extract_args(meta), do: meta

  @pandoc_flags ~w(
    --mathjax
    -f markdown+smart+emoji
    -t html
    --filter=pandoc-crossref
    --citeproc
  )

  def render_markdown_to_html(content, metadata_to_pandoc) do
    # 生成临时文件
    input_file = Path.join(System.tmp_dir!(), "input_#{System.unique_integer()}.md") |> IO.inspect()
    output_file = Path.join(System.tmp_dir!(), "output_#{System.unique_integer()}.html")

    # 写入内容（包含元数据）
    File.write!(input_file, build_front_matter(metadata_to_pandoc) <> "\n" <> content)

    # 调用 Pandoc
    res =
      get_pandoc()
      |> System.cmd(args(input_file, output_file), stderr_to_stdout: true)
      |> handle_result(output_file)

    File.rm(input_file)
    File.rm(output_file)

    res
  end

  defp args(input, output) do
    @pandoc_flags ++ [input, "-o", output]
  end

  defp build_front_matter(metadata) do
    if Map.keys(metadata) == [] do
      ""
    else
      res =
        metadata
        |> Enum.map(fn {k, v} -> "#{k}: #{v}" end)
        |> Enum.join("\n")

      """
      ---
      #{res}
      ---
      """
    end
  end

  defp handle_result({_, 0}, output_file) do
    File.read!(output_file)
  end

  defp handle_result({code, msg}, _) do
    raise "Pandoc failed with code #{code}: #{msg}"
  end
end
