defmodule GES233.Blog.Render.PostComponents do
  alias GES233.Blog.Post

  def show_tags(tags) do
    Enum.map(
      tags,
      &"""
      <svg width="14px" height="14px" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
        <path stroke-linecap="round" stroke-linejoin="round" d="M9.568 3H5.25A2.25 2.25 0 0 0 3 5.25v4.318c0 .597.237 1.17.659 1.591l9.581 9.581c.699.699 1.78.872 2.607.33a18.095 18.095 0 0 0 5.223-5.223c.542-.827.369-1.908-.33-2.607L11.16 3.66A2.25 2.25 0 0 0 9.568 3Z" />
        <path stroke-linecap="round" stroke-linejoin="round" d="M6 6h.008v.008H6V6Z" />
      </svg>
      <small>#{&1}</small>
      """
    )
    |> Enum.join("\n")
  end

  def appearance_status(progress) do
    case progress do
      :final ->
        """
        <svg width="14px" height="14px" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
          <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
        </svg><small>100%</small>
        """

      # 长期更新
      :longterm ->
        """
        <svg width="14px" height="14px" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
        </svg><small>100%</small>
        """

      [:longterm, progress] ->
        """
        <svg width="14px" height="14px" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
        </svg><small>#{progress}%</small>
        """

      [:wip, progress] ->
        """
        <svg width="14px" height="14px" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
          <path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L6.832 19.82a4.5 4.5 0 0 1-1.897 1.13l-2.685.8.8-2.685a4.5 4.5 0 0 1 1.13-1.897L16.863 4.487Zm0 0L19.5 7.125" />
        </svg><small>#{progress}%</small>
        """

      [:blocking, progress] ->
        """
        <svg width="14px" height="14px" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
          <path stroke-linecap="round" stroke-linejoin="round" d="m20.25 7.5-.625 10.632a2.25 2.25 0 0 1-2.247 2.118H6.622a2.25 2.25 0 0 1-2.247-2.118L3.75 7.5M10 11.25h4M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125Z" />
        </svg><small>#{progress}%</small>
        """
    end
  end

  def card(%Post{} = post, :article) do
    """
    <header class="heti-skip">
        <h2>#{post.title}</h2>
        <!--可以改成一个小的表格-->
        <div class="grid">
          <div class="grid">
            <div>
              <small>
              <svg width="14px" height="14px" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v6m3-3H9m12 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
              </svg>
              #{NaiveDateTime.to_date(post.create_at) |> Date.to_string()}
              </small>
            </div>
            <div>
              <small>
              <svg width="14px" height="14px" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
                <path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0 1 15.75 21H5.25A2.25 2.25 0 0 1 3 18.75V8.25A2.25 2.25 0 0 1 5.25 6H10" />
              </svg>
              #{NaiveDateTime.to_date(post.update_at) |> Date.to_string()}
              </small>
            </div>
          </div>
          <div>
            <small>进度</small>
            #{GES233.Blog.Render.PostComponents.appearance_status(post.progress)}
          </div>
        </div>
        <div class="pico">
          #{GES233.Blog.Render.PostComponents.show_tags(post.tags)}
        </div>
      </header>
    """
  end

  def card(%Post{} = post, :index) do
    """
    <article>
      <a href="#{Post.post_id_to_route(post)}"><h3>#{post.title}</h3></a>
      <p>
        <span>
          <svg width="14px" height="14px" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v6m3-3H9m12 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
          </svg>
          <small>#{NaiveDateTime.to_date(post.create_at) |> Date.to_string()}</small>
        </span>
        <span>#{appearance_status(post.progress)}</span>
      </p>
      <div>
        #{post.body}
      </div>
    </article>
    """
  end
end

defmodule GES233.Blog.Renderer.PageComponents do
  alias GES233.Blog.Page.Friend

  def friend(%Friend{} = friend) do
    avatar_part =
      if friend.avatar do
        """
        <div class="friend-avatar">
          <img src="#{friend.avatar}" alt="#{friend.name}" loading="lazy">
        </div>
        """
      else
        ""
      end

    desp_part =
      if friend.desp do
        """
        <hgroup>
          <h3>#{friend.name}</h3>
          <p>#{friend.desp}</p>
        </hgroup>
        """
      else
        """
        <h3>#{friend.name}</h3>
        """
      end

    site_link =
      if friend.site do
        if friend.site |> String.contains?("ges233") do
          """
            <button disabled class="outline"><a href="#{friend.site}" target="_blank" rel="noopener">就是这儿！</a></button>
          """
        else
          """
            <button class="outline"><a href="#{friend.site}" target="_blank" rel="noopener">让我访问！</a></button>
          """
        end
      else
        ""
      end

    """
    <div class="friend-card">#{avatar_part}<div class="friend-content">#{desp_part}#{site_link}</div></div>
    """
  end
end
