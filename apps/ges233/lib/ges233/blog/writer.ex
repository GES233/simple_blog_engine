defmodule GES233.Blog.Writer do
  require Logger
  alias GES233.Blog.{Post, Renderer, Media}

  @saved_path Application.compile_env(:ges233, :saved_path)

  ## Post related

  @spec write_post_html(GES233.Blog.Post.t(), binary(), any()) :: :ok
  def write_post_html(post, html_body, context) do
    path = Path.join(@saved_path, Post.post_id_to_route(post))

    full_html = GES233.Blog.Renderer.add_article_layout(html_body, post, context)

    path
    |> write_html(full_html)
    |> case do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.warning("Save not successed when saved post `#{post.id}` with #{inspect(reason)}")
    end
  end

  @spec write_index_page(integer(), [Post.t()], [any()]) :: :ok | {:error, any()}
  def write_index_page(page_num, posts_on_page, total_pages)

  def write_index_page(1, posts_on_page, total_pages) do
    write_html(
      "#{Application.get_env(:ges233, :saved_path)}/index.html",
      Renderer.add_index_layout(posts_on_page, 1, length(total_pages))
    )
  end

  def write_index_page(page_num, posts_on_page, total_pages) do
    write_html(
      "#{Application.get_env(:ges233, :saved_path)}/page/#{page_num}/index.html",
      Renderer.add_index_layout(posts_on_page, page_num, length(total_pages))
    )
  end

  defp write_html(abs_path, content) do
    File.mkdir_p(Path.dirname(abs_path))
    |> case do
      {:error, reason} ->
        Logger.error("Failed to create directory: #{abs_path}\n\ncaused by #{reason}")

      _ ->
        :ok
    end

    File.write(abs_path, content)
    # 不进行后续的 handle ，将处理的逻辑归为下游的对应函数
  end

  ## Media related

  @spec copy_media_asset(Media.t()) :: :ok | :error
  def copy_media_asset(media) do
    dest_path = Path.join(@saved_path, media.route_path)
    File.mkdir_p(Path.dirname(dest_path))

    File.copy(media.path, dest_path)
    |> case do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        Logger.warning(
          "File with id: #{media.id} copied not successfully due to #{inspect(reason)}"
        )
    end
  end

  ## Static

  @spec copy_static_to_path(%{term() => {binary(), binary()}}, %{
          term() => {binary(), binary()}
        }) :: :ok
  def copy_static_to_path(static_index, static_with_file_operate) do
    File.mkdir("#{Application.get_env(:ges233, :saved_path)}/assets")

    copy_with_log = fn source, target ->
      File.copy(source, target)
      |> case do
        {:ok, _} ->
          :ok

        {:error, reason} ->
          Logger.warning(
            "Static file #{source} copied not successfully due to #{inspect(reason)}"
          )
      end
    end

    Enum.map(
      Task.async_stream(
        static_index,
        fn {_name, {route, real}} ->
          copy_with_log.(real, "#{Application.get_env(:ges233, :saved_path)}/#{route}")
        end,
        max_concurrency: 4
      ),
      fn {:ok, _} -> :ok end
    )

    for {name, {target, source}} <- static_with_file_operate do
      files = FlatFiles.list_all(source)

      Enum.map(
        Task.async_stream(files, &single_file_oprate_in_dir_copy(&1, name, source, target),
          max_concurrency: 4
        ),
        fn {:ok, _} ->
          :ok
        end
      )
    end

    :ok
  end

  defp single_file_oprate_in_dir_copy(current_file, name, source, target) do
    target_f =
      current_file
      |> String.replace(source, "#{Application.get_env(:ges233, :saved_path)}/#{target}")

    target_f
    |> Path.split()
    |> :lists.droplast()
    |> Path.join()
    |> File.mkdir_p()
    |> case do
      {:error, reason} ->
        Logger.warning(
          "Static file directory #{Path.dirname(target_f)} within #{name} created not successfully due to #{inspect(reason)}"
        )

      _ ->
        :ok
    end

    current_file
    |> File.copy(target_f)
    |> case do
      {:ok, _} ->
        # Logger.info("Static file #{current_file} in #{name} copied successfully to #{target_f}")

        :ok

      {:error, reason} ->
        Logger.warning(
          "Static file #{current_file} in #{name} copied not successfully due to #{inspect(reason)}"
        )
    end
  end
end

# From
# https://www.thegreatcodeadventure.com/elixir-tricks-building-a-recursive-function-to-list-all-files-in-a-directory/
defmodule FlatFiles do
  def list_all(filepath) do
    _list_all(filepath)
  end

  defp _list_all(filepath) do
    cond do
      String.contains?(filepath, ".git") -> []
      true -> expand(File.ls(filepath), filepath)
    end
  end

  defp expand({:ok, files}, path) do
    files
    |> Enum.flat_map(&_list_all("#{path}/#{&1}"))
  end

  defp expand({:error, _}, path) do
    [path]
  end
end
