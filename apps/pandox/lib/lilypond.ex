defmodule Lilypond do
  require Logger

  # 自动查找 lilypond 可执行文件
  @executable System.find_executable("lilypond") || "lilypond"

  @doc """
  Executes the LilyPond CLI to convert a .ly file to an SVG string.
  """
  def execute(ly_path) do
    # 检查文件是否存在，提前返回错误
    unless File.exists?(ly_path) do
      Logger.error("LilyPond input file not found: #{ly_path}")
      {:error, {:not_found, "Input file not found"}}
    else
      output_base = Path.join(System.tmp_dir!(), Path.basename(ly_path, ".ly"))

      # 定义 CLI 参数
      args = [
        # 输出 SVG
        "--svg",
        # 移除 SVG 中的交互链接
        "-dno-point-and-click",
        # 指定输出路径和基础名
        "-o",
        output_base,
        ly_path
      ]

      # 调用 CLI 并处理结果
      System.cmd(@executable, args, stderr_to_stdout: true)
      |> handle_result(output_base)
    end
  end

  defp handle_result({output, 0}, output_base) do
    # 成功时，LilyPond 会在 output_base 的位置生成 .svg 文件
    # 文件名通常是 `base_name.svg`，但有时也可能是 `base_name-1.svg` 等
    # 我们用通配符来找到它
    case Path.wildcard("#{output_base}*.svg") do
      [svg_path | _] ->
        # 读取 SVG 文件内容并返回
        {:ok, File.read!(svg_path)}

      [] ->
        Logger.warning(
          "LilyPond executed successfully but no SVG file was found. Output:\n#{output}"
        )

        {:error, {:svg_not_found, output}}
    end
  end

  defp handle_result({output, exit_code}, _output_base) do
    # 失败时，返回退出码和错误输出
    {:error, {exit_code, output}}
  end
end
