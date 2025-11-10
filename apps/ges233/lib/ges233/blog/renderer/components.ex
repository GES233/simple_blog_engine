defmodule GES233.Blog.Renderer.PostComponents do
  alias GES233.Blog.Post

  def show_tags(tags) do
    for tag <- tags do
      """
      <div class="badge badge-outline badge-secondary">
        <svg class="size-[1rem]" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9.568 3H5.25A2.25 2.25 0 0 0 3 5.25v4.318c0 .597.237 1.17.659 1.591l9.581 9.581c.699.699 1.78.872 2.607.33a18.095 18.095 0 0 0 5.223-5.223c.542-.827.369-1.908-.33-2.607L11.16 3.66A2.25 2.25 0 0 0 9.568 3Z" />
          <path stroke-linecap="round" stroke-linejoin="round" d="M6 6h.008v.008H6V6Z" />
        </svg>
        <small>#{tag}</small>
      </div>
      """
    end
    |> Enum.join("\n")
  end

  def show_toc(toc) do
    EEx.eval_file("apps/ges233/templates/_components/post_or_page_toc.heex", toc: toc)
  end

  def appearance_status(progress) do
    EEx.eval_file("apps/ges233/templates/_components/post_status.heex", progress: progress)
  end

  def card(%Post{} = post, :article) do
    """
    <div>
      <h2 class="card-title text-2xl">#{post.title}</h2>

      <div class="flex flex-wrap items-center gap-x-6 gap-y-2 mt-3 text-base-content/80 text-sm">
        <span class="inline-flex items-center gap-1.5" title="创建日期">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" class="size-4">
            <path d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14Zm.75-10.25a.75.75 0 0 0-1.5 0v2.5h-2.5a.75.75 0 0 0 0 1.5h2.5v2.5a.75.75 0 0 0 1.5 0v-2.5h2.5a.75.75 0 0 0 0-1.5h-2.5v-2.5Z" />
          </svg>
          <span>#{NaiveDateTime.to_date(post.create_at) |> Date.to_string()}</span>
        </span>
        <span class="inline-flex items-center gap-1.5" title="更新日期">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" class="size-4">
            <path d="M13.488 2.513a1.75 1.75 0 0 0-2.475 0L3.75 9.775a.75.75 0 0 0-.22.53l-.823 2.882a.75.75 0 0 0 .963.963l2.882-.823a.75.75 0 0 0 .53-.22l7.262-7.263a1.75 1.75 0 0 0 0-2.474ZM4.53 10.28l6.738-6.737a.25.25 0 0 1 .353 0l1.148 1.147a.25.25 0 0 1 0 .354L6.03 11.782l-1.77.506.506-1.77Z" />
          </svg>
          <span>#{NaiveDateTime.to_date(post.update_at) |> Date.to_string()}</span>
        </span>
        <div>
          #{appearance_status(post.progress)}
        </div>
        #{show_tags(post.tags)}
      </div>
    """
  end

  def card(%Post{} = post, :index) do
    """
    <div class="card rounded-box grid my-6">
      <div class="card-body">
        <a href="#{Post.post_id_to_route(post)}"><h3 class="card-title text-lg">#{post.title}</h3></a>
        <div class="prose">
          #{post.body}
        </div>
        <div class="card-actions justify-end">
          <div class="badge badge-dash badge-primary">
            <svg class="size-[1rem]" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v6m3-3H9m12 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
            </svg>
            #{NaiveDateTime.to_date(post.create_at) |> Date.to_string()}
          </div>
          #{appearance_status(post.progress)}
        </div>
      </div>
    </div>
    """
  end
end

defmodule GES233.Blog.Renderer.PageComponents do
  alias GES233.Blog.Page.Friend

  def friend(%Friend{} = friend) do
    EEx.eval_file("apps/ges233/templates/_pages/friend.heex", friend: friend)
    |> String.replace("    ", "")
  end
end
