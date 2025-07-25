defmodule GES233.Blog.Media do
  @moduledoc """
  负责多媒体路由相关。

  乱七八糟的规矩：

  - 图片
    - 如果这个图片有系列的话（也就是在 /img 下面的文件夹的里边）那是 `![Your description](:{Seires-Id})`
    其将会变成 `![Your description](path/to/image)`
    - 如果在 /img 下面的话，那就是简单的 `:{ImageId}`
  - PDF
    - 简单的 `:{File-Id}` 其可以经 `GES233.Blog.Static.inject_when_pdf/1` 变成嵌入页面。
  - DOT
    - 其格式最好为 `:{Dot-FileId}` ，有可能被渲染为 `![Dot-FileId](path/to/compiled/svg)` 或
    `FileContentCodeBlockIfFailer`

  其中 `FileContentCodeBlockIfFailer` 就是可能存在错误的 DOT 文件内容。
  """
  require Logger

  @type t :: %__MODULE__{
          id: String.t(),
          type: :pic | :pdf | :dot,
          path: String.t(),
          route_path: String.t(),
          inner_content: String.t() | nil
        }
  defstruct [:id, :type, :path, :route_path, :inner_content]

  # Simply copy
  def get_media_under(path, :pic) do
    Path.wildcard(path <> "/**/*.{jpg,jpeg,png,webp}")
    |> Enum.map(&Task.async(fn -> parse_media(&1, :pic) end))
    |> Enum.map(&Task.await/1)
  end

  # Use pdf.js
  def get_media_under(path, :pdf) do
    Path.wildcard(path <> "**/*.pdf")
    |> Enum.map(&Task.async(fn -> parse_media(&1, :pdf) end))
    |> Enum.map(&Task.await/1)
  end

  ## Render

  # Graphviz graph(*.dot) -> svg
  def get_media_under(path, :dot) do
    Path.wildcard(path <> "**/*.dot")
    |> Enum.map(&Task.async(fn -> parse_media(&1, :dot) end))
    |> Enum.map(&Task.await/1)
  end

  # Music sheet snippet(*.ly) -> svg
  def get_media_under(path, :lilypond) do
    Path.wildcard(path <> "**/*.ly")
    |> Enum.map(&Task.async(fn -> parse_media(&1, :lilypond) end))
    |> Enum.map(&Task.await/1)
  end

  def parse_media(path) do
    [_, exp] = Path.basename(path) |> String.split(".", parts: 2)

    format =
      case exp do
        "dot" ->
          :dot

        "pdf" ->
          :pdf

        "ly" ->
          :lilypond

        _ ->
          cond do
            exp in ["jpg", "jpeg", "webp", "png"] -> :pic
            true -> :invalid
          end
      end

    parse_media(path, format)
  end

  def parse_media(path, :pic) do
    [series, image] = path |> Path.split() |> Enum.reverse() |> Enum.slice(1..2)

    [id_under_seires, ext] = Path.basename(path) |> String.split(".")

    id = [series, id_under_seires] |> Enum.join("-")

    case image do
      "img" ->
        %__MODULE__{
          id: id,
          type: :pic,
          path: path,
          route_path: "/image/#{series}/#{id_under_seires}.#{ext}"
        }

      _ ->
        %__MODULE__{
          id: id_under_seires,
          type: :pic,
          path: path,
          route_path: "/image/#{id_under_seires}.#{ext}"
        }
    end
  end

  def parse_media(path, :dot) do
    id = Path.basename(path, ".dot")

    case Graphviz.execute(path) do
      {:ok, svg} ->
        root = "#{Application.get_env(:ges233, :saved_path)}/svg"
        File.mkdir_p(root)

        path = "#{root}/#{id}.svg"
        File.write(path, svg)

        %__MODULE__{id: id, type: :dot, path: path, route_path: "![](/svg/#{id}.svg)"}

      {:error, {code, reason}} ->
        Logger.warning("DOT #{id} build failed with code #{code} and reason #{reason}")

        content = File.read(path)

        %__MODULE__{id: id, type: :dot, path: path, inner_content: content}
    end
  end

  def parse_media(path, :lilypond) do
    id = Path.basename(path, ".ly")

    case Lilypond.execute(path) do
      {:ok, svg} ->
        root = "#{Application.get_env(:ges233, :saved_path)}/svg"
        File.mkdir_p(root)

        path = "#{root}/#{id}.svg"
        File.write(path, svg)

        %__MODULE__{id: id, type: :lilypond, path: path, route_path: "![](/svg/#{id}.svg)"}

      {:error, {code, reason}} ->
        Logger.warning("DOT #{id} build failed with code #{code} and reason #{reason}")

        content = File.read(path)

        %__MODULE__{id: id, type: :lilypond, path: path, inner_content: content}
    end
  end

  def parse_media(path, :pdf) do
    id = Path.basename(path, ".pdf")

    %__MODULE__{id: id, type: :pdf, path: path, route_path: "/archive/pdf/#{id}.pdf"}
  end
end
