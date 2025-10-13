defmodule GES233.Blog.Static do
  alias GES233.Blog.Static.FlatFiles

  @static_index %{
    "phx" => {"/assets/phoenix_html.js", "apps/ges233/assets/vendor/phoenix_html.js"},
    "heti_css" => {"/assets/heti.min.css", "apps/ges233/assets/vendor/heti/heti.min.css"},
    "heti_js" => {"/assets/hti-addon.min.js", "apps/ges233/assets/vendor/heti/heti-addon.min.js"},
    "picocss" => {"/assets/picocss.min.css", "apps/ges233/assets/vendor/picocss.min.css"},
    # 如果想要更新主题的话：
    # https://github.com/jgm/pandoc/issues/7860#issuecomment-1938177020
    "highlight" =>
      {"/assets/code-highlighting.css",
       "apps/ges233/assets/vendor/pandoc/highlighting-breezedark.css"},
    "favicon" => {"/favicon.ico", "apps/ges233/assets/favicon.ico"}
  }

  @static_with_file_operate %{"pdf_js" => {"/dist/pdf_js", "apps/ges233/assets/vendor/pdf_js"}}

  def copy_to_path do
    File.mkdir("#{Application.get_env(:ges233, :saved_path)}/assets")

    for {_, {route, real}} <- @static_index do
      File.copy(real, "#{Application.get_env(:ges233, :saved_path)}/#{route}")
    end

    for {_, {target, source}} <- @static_with_file_operate do
      files = FlatFiles.list_all(source)

      for f <- files do
        target_f =
          String.replace(f, source, "#{Application.get_env(:ges233, :saved_path)}/#{target}")

        target_f |> Path.split() |> :lists.droplast() |> Path.join() |> File.mkdir_p()

        File.copy(f, target_f)
      end
    end

    :ok
  end

  # https://stackoverflow.com/questions/31052806/pandoc-escaping-iframes-during-markdown-to-html-convert
  def inject_when_pdf(inner) do
    "<div class=\"aspect-ratio\"><iframe src=\"/dist/pdf_js/web/viewer.html?file=#{inner}\"></iframe></div>"
  end

  def inject_to_assigns(opts \\ []) do
    phx_js = "<script src=\"#{get_route("phx")}\"></script>"
    picocss = "<link rel =\"stylesheet\" href=\"#{get_route("picocss")}\" >"
    heti_css = "<link rel=\"stylesheet\" href=\"#{get_route("heti_css")}\">"

    heti_js = """
    <script src="#{get_route("heti_js")}"></script>
    <script>
      const heti = new Heti('.heti');
      heti.autoSpacing();
    </script>
    """

    code = "<link rel=\"stylesheet\" href=\"#{get_route("highlight")}\">"

    _sober = """
    <script type="module" src="https://unpkg.com/sober@1.0.6/dist/main.js">
    </script>
    """

    friends = """
    <style>
      .friend-card {
        display: flex;
        align-items: flex-start;
        padding: 1.5rem;
        margin: 1rem 0;
        border: 1px solid #e1e5e9;
        border-radius: 8px;
        transition: all 0.2s ease;
      }

      .friend-card:hover {
        border-color: #3498db;
        box-shadow: 0 2px 8px rgba(52, 152, 219, 0.1);
      }

      .friend-avatar {
        flex-shrink: 0;
        margin-right: 1.5rem;
      }

      .friend-avatar img {
        width: 60px;
        height: 60px;
        border-radius: 50%;
        object-fit: cover;
        border: 2px solid #f1f3f4;
      }

      .friend-content {
        flex: 1;
      }

      /* 响应式设计 */
      @media (max-width: 768px) {
        .friend-card {
          flex-direction: column;
          text-align: center;
        }

        .friend-avatar {
          margin-right: 0;
          margin-bottom: 1rem;
        }

        .friend-avatar img {
          width: 80px;
          height: 80px;
        }
      }

      /* 网格布局容器样式 */
      .heti-skip {
        display: grid;
        gap: 1.5rem;
        grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      }
      </style>
    """

    opt = cond do
      :friends in opts -> "#{friends}"
      true -> ""
    end

    """
    #{phx_js}
    #{picocss}
    #{heti_css}
    #{heti_js}
    #{code}
    #{opt}
    """
  end

  defp get_route(item), do: @static_index[item] |> (fn {route, _} -> route end).()

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
end
