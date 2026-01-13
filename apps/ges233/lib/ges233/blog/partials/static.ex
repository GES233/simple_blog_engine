defmodule GES233.Blog.Static do
  alias GES233.Blog.Writer

  @static_index %{
    # 这个貌似是针对表单的
    # "phx" => {"/assets/phoenix_html.js", "apps/ges233/assets/vendor/phoenix_html.js"},
    "tailwind" => {"/assets/css/app.css", nil},
    "favicon" => {"/favicon.ico", "apps/ges233/assets/favicon.ico"},
    "abc_notation_plugin" =>
      {"/assets/abcjs-plugin-min.js", "apps/ges233/assets/vendor/abcjs/abcjs-plugin-min.js"},
    "abc_notation_basic" =>
      {"/assets/abcjs-basic-min.js", "apps/ges233/assets/vendor/abcjs/abcjs-basic-min.js"},
    "calendar" => {"/assets/calendar.js", "apps/ges233/assets/vendor/fullcalendar.js"}
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

  def inject_to_assigns(opts \\ %{}) do
    EEx.eval_file("apps/ges233/templates/_components/_assigns_in_head.heex",
      assigns: [options: opts, maybe_extra: nil]
    )
  end

  def get_route(item), do: @static_index[item] |> (fn {route, _} -> route end).()
end
