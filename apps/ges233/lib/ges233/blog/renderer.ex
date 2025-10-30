defmodule GES233.Blog.Renderer do
  alias GES233.Blog.{Bibliography, Static, Renderer, ContentRepo, Post, Page}

  def convert_markdown(post = %{}, opts) do
    all_posts_and_media = Keyword.get(opts, :meta)

    # callback_pre_pandoc = Keyword.get(opts, :pre_pandoc_callback, (& &1))
    # callback_after_pandoc = Keyword.get(opts, :pre_after_callback, (& &1))

    body = link_replace(post, all_posts_and_media)

    {post, %{}}
    # |> then(&callback_pre_pandoc)
    |> Bibliography.maybe_validate_bibliography_exist()
    |> Bibliography.ensure_bib_format()
    |> Bibliography.add_title_to_meta()
    |> Bibliography.postlude()
    |> then(&Pandox.render_markdown_to_html(body, &1))

    # |> then(&callback_after_pandoc)
  end

  defp link_replace(%{content: {:ref, id}}, posts_and_mata) do
    {:ok, raw} = ContentRepo.get_raw(id)

    GES233.Blog.Link.inner_replace(raw, posts_and_mata)
  end

  defp link_replace(%{content: pre}, posts_and_mata) when is_binary(pre) do
    GES233.Blog.Link.inner_replace(pre, posts_and_mata)
  end

  def add_article_layout(inner_html, post = %Post{}, _maybe_meta_about_blog) do
    inner_html
    |> Phoenix.HTML.raw()
    |> Phoenix.HTML.safe_to_string()
    |> then(
      &EEx.eval_file("apps/ges233/templates/article.html.heex",
        assigns: [
          post: post,
          meta: Static.inject_to_assigns(),
          inner_content: &1,
          post_title: Renderer.Title.in_article(post.title)
        ],
        engine: Phoenix.HTML.Engine
      )
    )
  end

  def add_index_layout(posts, page, total_pages) do
    EEx.eval_file(
      "apps/ges233/templates/list-article.html.heex",
      assigns: [
        posts: posts,
        page: page,
        total_pages: total_pages,
        meta: Static.inject_to_assigns(),
        page_title: Renderer.Title.in_list(page)
      ]
    )
  end

  def add_pages_layout(inner_html, page_struct = %Page{}) do
    friends? = page_struct.role == :friends

    opts =
      cond do
        friends? -> [:friends]
        true -> []
      end

    inner_html
    |> Phoenix.HTML.raw()
    |> Phoenix.HTML.safe_to_string()
    |> then(
      &EEx.eval_file("apps/ges233/templates/page.html.heex",
        assigns: [
          page: page_struct,
          meta: Static.inject_to_assigns(opts),
          inner_content: &1,
          page_title: Renderer.Title.in_article(page_struct.title)
        ],
        engine: Phoenix.HTML.Engine
      )
    )
  end
end
