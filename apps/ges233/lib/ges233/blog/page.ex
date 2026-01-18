defmodule GES233.Blog.Page do
  defstruct [
    :role,
    :title,
    :content,
    :body,
    :toc,
    extra: %{}
  ]

  @page_mapper %{
    about: {"about.md", "/about"},
    friends: {"friends.md", "/friends"}
  }
  @valid_roles Map.keys(@page_mapper)

  def get_all_path_partial, do: @valid_roles

  def all_in_one(meta_registry) do
    @valid_roles
    |> Enum.map(&location_to_struct/1)
    |> Enum.map(&add_html(&1, meta_registry))
  end

  def get_route_by_role(role) when is_atom(role) and role in @valid_roles do
    {_, route} = @page_mapper[role]

    route
  end

  def location_to_struct(role) do
    with {:ok, page_meta, raw} <- parse_page_file(role),
         content_meta = %{} <- raw |> get_page_meta() |> parse_page_meta(role) do
      page_meta
      |> Map.merge(content_meta)
      |> Map.merge(%{
        content:
          raw
          |> get_page_content()
          |> maybe_archive_large_content(role)
      })
      |> then(&struct!(__MODULE__, &1))
    else
      {:error, err} -> {:error, err, role}
      err -> {:error, err, role}
    end
  end

  def add_html(%__MODULE__{role: :friends} = page, meta) do
      page
      |> Map.merge(%{
        content:
          page.content
          |> EEx.eval_string(
            assigns: [
              friends: page.extra[:friends],
              self: %GES233.Blog.Page.Friend{
                name: "自留地 - GES233's Blog",
                site: "https://ges233.github.io",
                desp: "得以存在便是一个奇迹，能够思考就是一件乐事。",
                avatar: "https://avatars.githubusercontent.com/u/30802664?v=4"
              }
            ]
          )
      })
      |> GES233.Blog.Renderer.convert_markdown(meta: meta)
      |> then(&do_postlude(page, &1))
  end

  def add_html(page, meta) do
    GES233.Blog.Renderer.convert_markdown(page, meta: meta)
    |> then(&do_postlude(page, &1))
  end

  def do_postlude(page_or_post, doc_struct) do
    inner_body =
      if GES233.Blog.ContentRepo.enough_large?(doc_struct.body) do
        GES233.Blog.ContentRepo.cache_html(doc_struct.body, page_or_post.role)

        {:ref, page_or_post.role}
      else
        doc_struct.body
      end

    %{page_or_post | body: inner_body, toc: doc_struct.toc}
  end

  defp parse_page_file(role)
       when is_atom(role) and role in @valid_roles do
    path =
      "#{Application.get_env(:ges233, :page_entry)}/#{{location, _} = @page_mapper[role]
      location}"

    case File.exists?(path) do
      true ->
        {:ok, %{role: role}, File.read!(path)}

      false ->
        {:error, :file_not_exist}
    end
  end

  defp parse_page_meta(meta_in_metadata, _role), do: meta_in_metadata

  @doc """
  读取文件的元数据并且将其传递用作后用。

  当前形式是：

      ---
      %{blabla: blabla}
      ---

  也就是 Elixir 的 Nap。

  也兼容 YAML （原来博客的格式）。
  """
  def get_page_meta(content) do
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
  def get_page_content(content) do
    content
    |> :binary.split(["\n---\n", "\r\n---\r\n"])
    |> tl()
    |> hd()
  end

  @doc """
  将可能过大的内容本体放入 `GES233.Blog.ContentRepo` 。
  """
  def maybe_archive_large_content(content, id) do
    if GES233.Blog.ContentRepo.enough_large?(content) do
      GES233.Blog.ContentRepo.cache_raw(content, id)

      {:ref, id}
    else
      content
    end
  end
end
