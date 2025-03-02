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

  defstruct [
    :id,
    :title,
    :create_at,
    :update_at,
    :categories,
    :tags,
    :series,
    :content,
    extra: %{}
  ]

  @doc """
  从文件的目录到 `Post` 结构体的函数。
  """
  def build(path, extra_func \\ fn _meta_and_content -> %{} end) do
    with {:ok, file_meta, content} <- parse_post_file(path),
         content_meta = %{} <- get_post_meta(content) do
      infos =
        file_meta
        # |> opt
        # 将时间转变为 DateTime 格式
        |> Map.merge(%{
          title: content_meta[:title],
          categories: content_meta[:categories],
          tags: content_meta[:tags],
          series: content_meta[:series]
        })
        # title: 首个一级标题
        # categories: 条目（所属的树状结构）
        # tags: 标签
        # series: 系列
        |> Map.merge(%{content: get_post_content(content)})
        |> overwrite_create_date(content_meta)

      # 引入 extra
      # 后面可能会单独用一个函数来处理
      infos =
        infos
        |> Map.merge(extra_func.(content_meta))

      {:ok, struct!(__MODULE__, infos)}
    else
      {:error, err} -> {:error, err}
      err -> {:error, err}
    end
  end

  defp overwrite_create_date(meta, content_meta) do
    Map.put(meta, :create_at, content_meta[:create_at] || content_meta[:date] || meta[:create_at])
  end

  # TODO: convert to %DateTime{}
  # defp format_datetime_into_elixir(meta) do
  #   # ...
  # end

  defp parse_post_file(path) do
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
      %{blabla}
      ---

  也就是 Elixir 的 Nap。

  后期可能也会兼容 YAML （原来博客的格式）。
  """
  def get_post_meta(content, format \\ :map)

  def get_post_meta(content, :map) do
    content
    |> :binary.split(["\n---\n", "\r\n---\r\n"])
    |> hd()
    |> :binary.split(["---\n", "---\r\n"])
    |> tl()
    |> hd()
    |> Code.eval_string()
    |> case do
      {%{} = meta, _binding} -> meta
      _ -> :invalid_map
    end
  end

  def get_post_meta(content, :yaml) do
    content
    |> :binary.split(["\n---\n", "\r\n---\r\n"])
    |> hd()
    |> :binary.split(["---\n", "---\r\n"])
    |> tl()
    |> hd()
    # ...
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
