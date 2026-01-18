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

  alias GES233.Blog.{Post, Page, Context}

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
          toc: String.t() | nil,
          doc: Pandox.Doc.t(),
          progress: any(),
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
    toc: nil,
    doc: nil,
    progress: :final,
    extra: %{}
  ]

  @doc """
  从文件的目录到 `Post` 结构体的函数。
  """
  def path_to_struct(
        path,
        extra_func \\ fn meta_and_content ->
          %{
            extra: meta_and_content[:extra] || %{}
          }
        end
      ) do
    with {:ok, file_meta, content} <- parse_post_file(path),
         content_meta = %{} <- Page.get_page_meta(content) do
      file_meta
      |> Map.merge(%{
        title: content_meta[:title],
        categories: content_meta[:categories],
        tags: content_meta[:tags],
        series: content_meta[:series],
        progress: content_meta[:progress] || :final
      })
      ## 时间相关
      |> overwrite_create_date(content_meta)
      |> overwrite_update_date(
        path
        |> Path.split()
        |> Enum.reverse()
        |> tl()
        |> tl()
        |> Enum.reverse()
        |> Path.join()
      )
      |> then(fn d -> %{d | create_at: convert_date(d[:create_at])} end)
      |> then(fn d -> %{d | update_at: convert_date(d[:update_at])} end)
      ## 整理单独博客的标签
      |> then(fn d -> %{d | tags: :lists.flatten(d.tags)} end)
      |> Map.merge(extra_func.(content_meta))
      ## 引入内容相关
      # 如果内容过大的话可能会变成 {:ref, id}
      |> Map.merge(%{
        content:
          content
          |> Page.get_page_content()
          # |> Page.maybe_archive_large_content(file_meta[:id])
      })
      ## 构建 %Post{}
      |> then(&struct!(__MODULE__, &1))
    else
      {:error, err} -> {:error, err, path}
      err -> {:error, err, path}
    end
  end

  @spec post_id_to_route(GES233.Blog.Post.t()) :: nonempty_binary()
  def post_id_to_route(post = %__MODULE__{}) do
    date =
      post.create_at
      |> NaiveDateTime.to_date()
      |> Date.to_string()
      |> String.split("-")
      |> Enum.drop(-1)

    "/#{Enum.join(date ++ [post.id], "/")}"
  end

  @spec add_html(GES233.Blog.Post.t(), Context.meta_registry()) :: GES233.Blog.Post.t()
  def add_html(%__MODULE__{} = post, meta) do
    doc_struct = GES233.Blog.Renderer.convert_markdown(post, meta: meta)

    %{post |  doc: doc_struct, toc: doc_struct.toc}
  end

  defp overwrite_create_date(meta, content_meta) do
    maybe_create_from_file = content_meta[:create_at] || content_meta[:date]

    Map.put(meta, :create_at, maybe_create_from_file || meta[:create_at])
  end

  # 期望是从 Git 的提交记录找
  # 对于未提交的情况，按照
  defp overwrite_update_date(meta, root_path) do
    maybe_update_from_git_commit =
      Git.execute_command(
        %Git.Repository{path: root_path},
        "log",
        ~w(--pretty=format:\"%cd\" --date=iso-strict -1 _posts/#{meta.id}.md),
        fn date_string ->
          date_string
          |> String.replace(~r("), "")
          |> DateTime.from_iso8601()
          |> case do
            # Uncommit file.
            {:ok, commit_time, _} -> commit_time
            _ -> DateTime.now!("Asia/Shanghai")
          end
        end
      )

    Map.put(meta, :update_at, maybe_update_from_git_commit)
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

  def get_post_from_id([%Post{} | _] = posts_repo, id) do
    Enum.find(posts_repo, &(&1.id == id))
  end
end
