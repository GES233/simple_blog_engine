defmodule GES233.Blog.Writer do
  alias GES233.Blog.Writer.SinglePage, as: WriterSingle
  alias GES233.Blog.{Post, Page, Renderer, Media, Context, ContentRepo}

  @page_pagination Application.compile_env(:ges233, [:Blog, :page_pagination])

  @spec write_index(Context.t()) :: Context.t()
  def write_index({meta_registry, _index_registry} = context) do
    pages =
      meta_registry
      |> Enum.map(fn {_, v} -> v end)
      |> Enum.filter(&is_struct(&1, Post))
      |> Enum.sort_by(& &1.create_at, {:desc, NaiveDateTime})
      |> pagination([])

    pages
    |> length()
    |> then(&Range.new(1, &1))
    |> Enum.zip(pages)
    |> Task.async_stream(fn {index, page} -> WriterSingle.write_index_page(index, page, pages) end,
      max_concurrency: System.schedulers_online()
    )
    |> Stream.run()

    context
  end

  @spec write_standalone_pages(Context.t()) :: Context.t()
  def write_standalone_pages({_meta_registry, %{"single_pages" => pages}} = context) do
    Task.async_stream(pages, fn page ->
      [
        Application.get_env(:ges233, :saved_path) |> Path.absname(),
        page.role |> Page.get_route_by_role(),
        "index.html"
      ]
      |> Path.join()
      |> WriterSingle.write_single_page(
        Renderer.add_pages_layout(get_body_from_page(page), page)
      )
    end)
    |> Stream.run()

    context
  end

  defp pagination(list, pages) when length(list) <= @page_pagination do
    [list | pages] |> :lists.reverse()
  end

  defp pagination(list, pages) do
    {page, rest} = Enum.split(list, @page_pagination)

    pagination(rest, [page | pages])
  end

  @spec copy_users_assets(Context.meta_registry()) :: Context.meta_registry()
  def copy_users_assets(meta_registry) do
    meta_registry
    |> Enum.map(fn {_, v} -> v end)
    # dot 生成的 svg 直接被别的函数解决了，不需要再 copy
    |> Enum.filter(&(is_struct(&1, Media) && &1.type in [:pic, :pdf]))
    |> Task.async_stream(&WriterSingle.copy_media_asset/1)
    |> Stream.run()

    meta_registry
  end

  defp get_body_from_page(page) do
    {status, html} = ContentRepo.get_html(page.role)

    case status do
      :ok ->
        html

      :error ->
        page.body
    end
  end
end

defmodule GES233.Blog.Writer.SinglePage do
  require Logger
  alias GES233.Blog.{Post, Renderer, Media}

  @saved_path Application.compile_env(:ges233, :saved_path)

  ## HTML related

  @spec write_post_html(GES233.Blog.Post.t(), binary(), any()) :: :ok
  def write_post_html(post, html_body, context) do
    full_html = GES233.Blog.Renderer.add_article_layout(html_body, post, context)

    [@saved_path, Post.post_id_to_route(post), "index.html"]
    |> Path.join()
    |> write_html(full_html)
    |> case do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.warning("Save not successed when saved post `#{post.id}` with #{inspect(reason)}")
    end
  end

  @spec write_single_page(binary(), binary()) :: :ok
  def write_single_page(abs_path, inner_html) do
    write_html(abs_path, inner_html)
    |> case do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.warning(
          "Save not successed when saved single page `#{abs_path}` with #{inspect(reason)}"
        )
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
        max_concurrency: System.schedulers_online()
      ),
      fn {:ok, _} -> :ok end
    )

    for {name, {target, source}} <- static_with_file_operate do
      files = FlatFiles.list_all(source)

      Enum.map(
        Task.async_stream(files, &single_file_oprate_in_dir_copy(&1, name, source, target),
          max_concurrency: System.schedulers_online()
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

  ## Git

  def copy_all_files_except_git(target_path) do
    deploy_file_list =
      Application.get_env(:ges233, :saved_path)
      |> FlatFiles.list_all()

    do_copy = fn file ->
      target_f = String.replace(file, "#{Application.get_env(:ges233, :saved_path)}", target_path)

      target_f
      |> Path.split()
      |> :lists.droplast()
      |> Path.join()
      |> File.mkdir_p()
      |> case do
        {:error, reason} ->
          Logger.warning(
            "Directory #{Path.dirname(target_f)} created not successfully due to #{inspect(reason)}"
          )

        _ ->
          nil
      end

      File.copy(file, target_f)
      |> case do
        {:ok, _} ->
          :ok

        {:error, reason} ->
          Logger.warning(
            "File #{file} copied not successfully due to #{inspect(reason)}"
          )
      end
    end

    Task.async_stream(deploy_file_list, do_copy, max_concurrency: System.schedulers_online())
    |> Stream.run()
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
