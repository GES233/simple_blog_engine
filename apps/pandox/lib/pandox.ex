defmodule Pandox do
  @moduledoc """
  Documentation for `Pandox`.
  """

  # 默认的 pandoc 可执行文件的地址
  # （我假定你是通过 Scoop/apt/Homebrew 等方式安装的）
  @pandoc_executable_name System.find_executable("pandoc") || "pandoc"

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
  )

  @pandoc_crossref_flags ~w(
    --filter=pandoc-crossref
    --citeproc
  )

  def render_markdown_to_html(content, metadata_to_pandoc) do
    # 生成临时文件
    input_file = Path.join(System.tmp_dir!(), "input_#{System.unique_integer()}.md")
    output_file = Path.join(System.tmp_dir!(), "output_#{System.unique_integer()}.html")

    # 写入内容（包含元数据）
    File.write!(input_file, build_front_matter(metadata_to_pandoc) <> "\n" <> content)

    # 调用 Pandoc
    res =
      args(input_file, output_file)
      # |> IO.inspect(label: :Args)
      # 使用 System.cmd 会报错
      # |> then(&System.cmd(get_pandoc(), &1))
      |> Enum.join(" ")
      |> then(&System.shell("#{get_pandoc()} #{&1}"))
      |> handle_result(output_file)

    File.rm(input_file)
    File.rm(output_file)

    res
  end

  def args(input, output) do
    yaml_path = Application.get_env(:pandox, :crossref_yaml)

    yaml =
      if yaml_path do
        "-M crossrefYaml=\"" <> yaml_path <> "\""
      else
        ""
      end

    csl_path = Application.get_env(:pandox, :csl)["GB7714"]

    csl =
      if csl_path do
        "--csl=\"" <> csl_path <> "\""
      else
        ""
      end

    lua_root_path = Application.get_env(:pandox, :lua_filters)["structure"]
    lua_filter = if lua_root_path do
        ["--lua-filter=\"" <> lua_root_path <> "\""]
      else
        []
      end

    # 可以作为一个选项
    maybe_toc_flag =
      case Application.get_env(:pandox, :toc_template) do
        nil ->
          []

        template_with_toc ->
          ~w(
          --toc
          --template
          #{template_with_toc}
        )
      end

    # 获得模板
    # https://stackoverflow.com/questions/62774695/pandoc-where-are-css-files-for-syntax-highlighting-code
    # pandoc --print-default-template=html5

    @pandoc_flags ++ @pandoc_crossref_flags ++ lua_filter ++ maybe_toc_flag ++ [yaml, csl, input, "-o", output]
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
    File.read!(output_file) |> parse_pandoc_output()
  end

  defp handle_result({code, msg}, _) do
    raise "Pandoc failed with code #{code}: #{msg}"
  end

  ## == Postlude ==

  defmodule Doc do
    @type t :: %__MODULE__{
      body: binary(),
      toc: binary() | nil,
      summary: binary() | nil,
      bibliography: binary() | nil,
      footnotes: binary() | nil,
      meta: term()
    }
    defstruct [:body, :toc, :summary, :bibliography, :footnotes, :meta]
  end

  defp parse_pandoc_output(raw_output) do
    # 使用正则或字符串分割提取各个部分
    # 这里写一个通用的提取器
    extract = fn section_name ->
      regex = ~r/<!--SECTION_START:#{section_name}-->(.*?)<!--SECTION_END:#{section_name}-->/s
      case Regex.run(regex, raw_output) do
        [_, content] -> String.trim(content)
        nil -> nil
      end
    end

    %Doc{
      body: extract.("BODY"),
      toc: extract.("TOC"),
      summary: extract.("SUMMARY"),
      bibliography: extract.("BIB"),
      footnotes: extract.("NOTES"),
      # 如果你需要回传元数据，甚至可以让 Pandoc 输出 JSON
      meta: extract.("META") # 或者从 Pandoc 输出中解析
    }
  end
end
