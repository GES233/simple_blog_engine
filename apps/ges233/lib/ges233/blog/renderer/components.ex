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
    """
    <details class="dropdown">
      <summary class="btn btn-xs sm:btn-sm md:btn-md lg:btn-lg xl:btn-xl btn-outline btn-secondary">
        目录
      </summary>
        #{
          toc
          |> String.replace(
            "<ul>",
            ~S(<ul class="menu dropdown-content bg-base-100 rounded-box z-1 w-52 p-2 shadow-sm">),
            global: false
          )
        }
    </details>
    """
  end

  def appearance_status(progress) do
    case progress do
      :final ->
        """
        <div class="badge badge-success badge-outline">
          <svg class="size-[1rem]" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
            <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
          </svg>
          <div title="进度" class="radial-progress text-info" style="--value:100; --size:1rem; --thickness: 2px;" aria-valuenow="100" role="progressbar">
          </div>
            100%
        </div>
        """

      # 长期更新
      :longterm ->
        """
        <div class="badge badge-outline badge-success">
          <svg class="size-[1rem]" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
          </svg>
          <div title="进度" class="radial-progress text-info" style="--value:100; --size:1rem; --thickness: 2px;" aria-valuenow="100" role="progressbar">
          </div>
          100%
        </div>
        """

      [:longterm, progress] ->
        """
        <div class="badge badge-info badge-outline">
          <svg class="size-[1rem]" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
          </svg>
          <div title="进度" class="radial-progress text-info" style="--value:#{progress}; --size:1rem; --thickness: 2px;" aria-valuenow="#{progress}" role="progressbar">
          </div>
          #{progress}%
        </div>
        """

      [:wip, progress] ->
        """
        <div class="badge badge-info badge-outline">
          <svg class="size-[1rem]" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
            <path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L6.832 19.82a4.5 4.5 0 0 1-1.897 1.13l-2.685.8.8-2.685a4.5 4.5 0 0 1 1.13-1.897L16.863 4.487Zm0 0L19.5 7.125" />
          </svg>
          <div title="进度" class="radial-progress text-info" style="--value:#{progress}; --size:1rem; --thickness: 2px;" aria-valuenow="#{progress}" role="progressbar">
          </div>
          #{progress}%
        </div>
        """

      [:blocking, progress] ->
        """
        <div class="badge badge-outline badge-ghost">
          <svg class="size-[0.8rem]" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
            <path stroke-linecap="round" stroke-linejoin="round" d="m20.25 7.5-.625 10.632a2.25 2.25 0 0 1-2.247 2.118H6.622a2.25 2.25 0 0 1-2.247-2.118L3.75 7.5M10 11.25h4M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125Z" />
          </svg>
          <div title="进度" class="radial-progress text-info" style="--value:#{progress}; --size:1rem; --thickness: 2px;" aria-valuenow="#{progress}" role="progressbar">
          </div>
          #{progress}%
        </div>
        """
    end
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
    avatar_part =
      if friend.avatar do
        """
        <figure><img src="#{friend.avatar}" alt="#{friend.name}" /></figure>
        """
      else
        ""
      end

    desp_part =
      if friend.desp do
        """
        <p class="text-base-content/70">#{friend.desp}</p>
        """
      else
        ""
      end

    site_link =
      if friend.site do
        if friend.site |> String.contains?("ges233") do
          """
            <button disabled="disabled" class="btn btn-dash btn-secondary">
              就是这儿！
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4">
                <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 6H5.25A2.25 2.25 0 0 0 3 8.25v10.5A2.25 2.25 0 0 0 5.25 21h10.5A2.25 2.25 0 0 0 18 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25" />
              </svg>
            </button>
          """
        else
          """
            <a href="#{friend.site}" target="_blank" rel="noopener" class="btn btn-primary">
              让我访问！
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4">
                <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 6H5.25A2.25 2.25 0 0 0 3 8.25v10.5A2.25 2.25 0 0 0 5.25 21h10.5A2.25 2.25 0 0 0 18 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25" />
              </svg>
            </a>
          """
        end
      else
        ""
      end

    """
    <div class="card lg:card-side lg:h-72 bg-base-100 shadow-sm shadow-xl">
      #{avatar_part}
      <div class="card-body">
        <h2 class="card-title">#{friend.name}</h2>
        #{desp_part}
        <div class="card-actions justify-end">#{site_link}</div>
      </div>
    </div>
    """
    |> String.replace("    ", "")
  end
end
