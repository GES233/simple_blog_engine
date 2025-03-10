defmodule GES233.Blog.Renderer do
  alias GES233.Blog.{Post, Bibliography, Static}

  def convert_markdown(post = %Post{}, opts) do
    all_posts_and_media = Keyword.get(opts, :meta)

    body = link_replace(post, all_posts_and_media)

    {post, %{}}
    |> Bibliography.maybe_validate_bibliography_exist()
    |> Bibliography.ensure_bib_format()
    |> Bibliography.add_title_to_meta()
    |> Bibliography.postlude()
    # 先过一遍 Pandox
    |> then(&Pandox.render_markdown_to_html(body, &1))

    # 再过一遍 PhoenixHTML
  end

  defp link_replace(%Post{content: {:ref, id}}, posts_and_mata) do
    {:ok, raw} = Post.ContentRepo.get_raw(id)

    GES233.Blog.Link.inner_replace(raw, posts_and_mata)
  end

  defp link_replace(%Post{content: pre}, posts_and_mata) when is_binary(pre) do
    GES233.Blog.Link.inner_replace(pre, posts_and_mata)
  end

  def add_article_layout(inner_html, post, _maybe_meta_about_blog) do
    inner_html
    |> Phoenix.HTML.raw()
    |> Phoenix.HTML.safe_to_string()
    |> then(
      &EEx.eval_file("apps/ges233/templates/article.html.heex",
        assigns: [post: post, meta: Static.inject_to_assigns(), inner_content: &1],
        engine: Phoenix.HTML.Engine
      )
    )
  end

  def add_page_layout(posts, page, total_pages) do
    EEx.eval_file(
      "apps/ges233/templates/list-article.html.heex",
      assigns: [
        posts: posts,
        page: page,
        total_pages: total_pages,
        meta: Static.inject_to_assigns(),
        page_title: "首页"
      ]
    )
  end
end
