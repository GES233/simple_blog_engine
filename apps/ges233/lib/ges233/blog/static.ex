defmodule GES233.Blog.Static do
  alias GES233.Blog.Writer

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
    "favicon" => {"/favicon.ico", "apps/ges233/assets/favicon.ico"},
    "abc_notation" =>
      {"/assets/abcjs-plugin-min.js", "apps/ges233/assets/vendor/abcjs-plugin-min.js"}
  }

  @static_with_file_operate %{"pdf_js" => {"/dist/pdf_js", "apps/ges233/assets/vendor/pdf_js"}}

  ## 对文件的复制/移动操作

  def copy_static,
    do: Writer.SinglePage.copy_static_to_path(@static_index, @static_with_file_operate)

  ## 对页面 HTML 的操作

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

    sse_script =
      if Mix.env() == :dev do
        """

        <script type="text/javascript">
          const eventSource = new EventSource("/sse");

          eventSource.addEventListener("reload", (e) => {
            // console.log("Server sent reload event. Reloading page...");
            window.location.reload();
            // console.log("Reload complete.");
          });

          eventSource.onerror = (err) => {
            console.error("EventSource failed:", err);
            eventSource.close();
          };
        </script>
        """
      else
        ""
      end

    # TODO: Migrate in inject_with_options
    mathjax = """
    <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
    """

    music = """
      <script src="#{get_route("abc_notation")}">
      </script>
    """

    inject_with_options =
      if(:friends in opts, do: friends <> "\n", else: <<>>)
      <> if(:render_sheet in opts, do: music <> "\n", else: <<>>)

    """
    #{phx_js}
    #{picocss}
    #{heti_css}
    #{heti_js}
    #{code}
    #{mathjax}
    #{inject_with_options}#{sse_script}
    """
  end

  defp get_route(item), do: @static_index[item] |> (fn {route, _} -> route end).()
end
