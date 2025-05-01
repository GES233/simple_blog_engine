defmodule GES233.Blog.Post.RegistryBuilder do
  alias GES233.Blog.{Post, Media}

  @pic_entry Application.compile_env(:ges233, [:Media, :pic_path])
  @pdf_entry Application.compile_env(:ges233, [:Media, :pdf_path])
  @dot_entry Application.compile_env(:ges233, [:Media, :dot_path])

  @type post_registry :: %{atom() => Post.t()}

  def build_posts_registry(posts) do
    posts
    |> Enum.map(&Task.async(fn -> remove_raw_and_html(&1) end))
    |> Enum.map(&Task.await/1)
    |> Enum.map(fn post -> {post.id, post} end)

    # |> Enum.into(%{})
  end

  def build_media_registry(root_path, format) do
    cond do
      format in [:pic, :pdf, :dot] ->
        Media.get_media_under(root_path, format)
        |> Enum.map(fn m -> {m.id, m} end)

      true ->
        nil
    end

    # Load to registry with type
  end

  defp remove_raw_and_html(post = %Post{}) do
    %{post | content: nil, body: nil}
  end

  def get_meta_registry(posts) do
    ((build_posts_registry(posts) ++
        build_media_registry(@pic_entry, :pic) ++
        build_media_registry(@pdf_entry, :pdf) ++
        build_media_registry(@dot_entry, :dot)) ++
       [])
    |> Enum.into(%{})
  end
end
