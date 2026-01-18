defmodule GES233.Blog.Renderer do
  alias GES233.Blog.{Bibliography, Static, Renderer, ContentRepo, Post, Page}

  def convert_markdown(post = %{}, opts) do
    all_posts_and_media = Keyword.get(opts, :meta)

    # callback_pre_pandoc = Keyword.get(opts, :pre_pandoc_callback, (& &1))
    # callback_after_pandoc = Keyword.get(opts, :pre_after_callback, (& &1))

    {post, body} = link_replace(post, all_posts_and_media)

    {post, %{}}
    |> Bibliography.maybe_validate_bibliography_exist()
    |> Bibliography.ensure_bib_format()
    |> Bibliography.add_title_to_meta()
    |> Bibliography.postlude()
    |> then(&Pandox.render_markdown_to_html(body, &1))
  end

  defp link_replace(%{content: {:ref, id}} = post_or_page, posts_and_mata) do
    {:ok, raw} = ContentRepo.get_raw(id)

    link_replace_inject(post_or_page, raw, posts_and_mata)
  end

  defp link_replace(%{content: pre} = post_or_page, posts_and_mata) when is_binary(pre) do
    link_replace_inject(post_or_page, pre, posts_and_mata)
  end

  # TODO: 改成像 Post / Page 内的 extra 添加对应的变量
  defp link_replace_inject(post_or_page, content, posts_and_mata) do
    case GES233.Blog.Link.inner_replace(content, posts_and_mata) do
      {nil, content} ->
        {post_or_page, content}

      {:replaced, content} ->
        # TODO: 添加注入流程
        # 1. 找到 extra
        # 2. 添加 %{pdf: ture}
        {post_or_page, content}
    end
  end

  def add_article_layout(inner_html, post = %Post{}, _maybe_meta_about_blog) do
    # Inject
    assigns =
      case Map.fetch(post, :extra) do
        {:ok, extra} -> Enum.into(extra, %{})
        :error -> %{}
      end

    inner_html =
      inner_html
      |> Phoenix.HTML.raw()
      |> Phoenix.HTML.safe_to_string()

    EEx.eval_file("apps/ges233/templates/article.html.heex",
      assigns: [
        post: post,
        meta: Static.inject_to_assigns(assigns),
        inner_content: inner_html,
        post_title: Renderer.Title.in_article(post.title)
      ],
      engine: Phoenix.HTML.Engine
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
        friends? -> %{friends: true}
        true -> %{}
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
