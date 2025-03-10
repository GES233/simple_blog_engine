defmodule GES233.Blog.Renderer.Title do
  @site_title "自留地"
  # @site_description ""

  def in_article(post_title) do
    "#{post_title} - #{@site_title}"
  end

  def in_list(page_num) do
    "{{Blabla}} :: #{page_num |> Integer.to_string()}"
  end

  def about() do
    "关于 - #{@site_title}"
  end
end
