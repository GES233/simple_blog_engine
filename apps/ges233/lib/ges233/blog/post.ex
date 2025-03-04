defmodule GES233.Blog.Post do
  @moduledoc """
  以下是博客的示例

      ---
      %{}
      ---

      ### 正文

      你好，世界。

  文件标头的元数据设置：

  * `:title` 标题
  * `:create_at` 创建时间（覆写来自文件的元数据）
  * `:categories`
  * `:tags` 标签
  * `:series` （如果有分系列的话）

  也可能会存在额外的元数据。
  """

  alias GES233.Blog.Post

  @type t :: %__MODULE__{
          id: atom() | String.t(),
          title: String.t(),
          create_at: NaiveDateTime.t(),
          update_at: NaiveDateTime.t(),
          categories: [[String.t()]],
          tags: [String.t()],
          series: String.t() | nil,
          content: String.t(),
          body: String.t(),
          progress: :final | {:in_progress, number()},
          extra: %{}
        }
  defstruct [
    :id,
    :title,
    :create_at,
    :update_at,
    :categories,
    :tags,
    :series,
    :content,
    :body,
    progress: :final,
    extra: %{}
  ]

  def build(path, _content_meta, html_body) do
    # TODO: 可以并行化设计
    # 读取文件就一个进程
    # 但是解析可以分给很多个 Tasks

    %{path_to_struct(path) | body: html_body}
  end

  @doc """
  从文件的目录到 `Post` 结构体的函数。
  """
  def path_to_struct(path, extra_func \\ fn _meta_and_content -> %{} end) do
    with {:ok, file_meta, content} <- parse_post_file(path),
         content_meta = %{} <- get_post_meta(content) do
      file_meta
      |> Map.merge(%{
        title: content_meta[:title],
        categories: content_meta[:categories],
        tags: content_meta[:tags],
        series: content_meta[:series]
      })
      |> overwrite_create_date(content_meta)
      # 更新时间格式
      |> then(fn d -> %{d | create_at: convert_date(d[:create_at])} end)
      |> then(fn d -> %{d | update_at: convert_date(d[:update_at])} end)
      # Cleaning tags
      |> then(fn d -> %{d | tags: :lists.flatten(d.tags)} end)
      # TODO: 解析进度相关
      # TODO: 引入 extra
      # 后面可能会单独用一个函数来处理
      |> Map.merge(extra_func.(content_meta))
      # 引入内容相关
      # 如果内容过大的话可能会变成 {:ref, id}
      |> Map.merge(%{content: get_post_content(content)})
      |> then(&struct!(__MODULE__, &1))
    else
      {:error, err} -> {:error, err, path}
      err -> {:error, err, path}
    end
  end

  def add_html_without_nimble(post) do
    html_body =
      GES233.Blog.Renderer.convert_mardown(post.content, Map.get(post.extra, :pandoc, %{}), [])

    %{post | body: html_body}
  end

  defp overwrite_create_date(meta, content_meta) do
    maybe_create_from_file = content_meta[:create_at] || content_meta[:date]

    Map.put(meta, :create_at, maybe_create_from_file || meta[:create_at])
  end

  defp convert_date(%DateTime{} = datetime), do: datetime

  defp convert_date(datetime) when is_tuple(datetime) do
    NaiveDateTime.from_erl!(datetime)
  end

  defp convert_date(datetime) when is_binary(datetime) do
    NaiveDateTime.from_iso8601!(datetime)
  end

  defp parse_post_file(path) when is_binary(path) do
    case File.exists?(path) do
      true ->
        # 读取文件相关信息
        # id: 文章名
        id = get_post_id(path)

        # xxx_at: 创建/更新于
        {:ok, %{mtime: update_at, ctime: create_at}} = File.stat(path)

        {:ok, %{id: id, create_at: create_at, update_at: update_at}, File.read!(path)}

      false ->
        {:error, :file_not_exist}
    end
  end

  def get_post_id(path) do
    path |> Path.basename() |> String.split(".") |> hd()
  end

  @doc """
  读取文件的元数据并且将其传递用作后用。

  当前形式是：

      ---
      %{blabla: blabla}
      ---

  也就是 Elixir 的 Nap。

  也兼容 YAML （原来博客的格式）。
  """
  def get_post_meta(content) do
    meta =
      content
      |> :binary.split(["\n---\n", "\r\n---\r\n"])
      |> hd()
      |> :binary.split(["---\n", "---\r\n"])
      |> tl()
      |> hd()

    format =
      cond do
        String.starts_with?(meta, "%{") -> :map
        true -> :yaml
      end

    get_meta_from_map(meta, format)
  end

  defp get_meta_from_map(meta, :map) do
    meta
    |> Code.eval_string()
    |> case do
      {%{} = meta, _binding} -> meta
      _ -> :invalid_map
    end
  end

  defp get_meta_from_map(meta, :yaml) do
    meta
    |> YamlElixir.read_from_string!(atoms: true)
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    |> Enum.into(%{})
  end

  @doc """
  获取博客内容。
  """
  def get_post_content(content) do
    content |> :binary.split(["\n---\n", "\r\n---\r\n"]) |> tl() |> hd()
  end

  def get_post_from_id([%Post{} | _] = posts_repo, id) do
    Enum.find(posts_repo, &(&1.id == id))
  end
end
