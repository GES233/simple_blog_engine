defmodule GES233.Blog.Static do
  # format {route_path, real_path}
  @static_index %{
    "phx" => {"/assets/phoenix_html.js", "apps/ges233/assets/vendor/phoenix_html.js"},
    "heti_css" => {"/assets/heti.min.css", "apps/ges233/assets/vendor/heti/heti.min.css"},
    "heti_js" => {"/assets/hti-addon.min.js", "apps/ges233/assets/vendor/heti/heti-addon.min.js"},
    "picocss" => {"/assets/picocss.min.css", "apps/ges233/assets/vendor/picocss.min.css"}
    # TODO: Code highlighting & PicoCSS
  }

  def copy_to_path do
    File.mkdir("#{Application.get_env(:ges233, :saved_path)}/assets")

    for {_, {route, real}} <- @static_index do
      File.copy(real, "#{Application.get_env(:ges233, :saved_path)}/#{route}")
    end

    :ok
  end

  def inject_to_assigns do
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

    """
    #{phx_js}
    #{picocss}
    #{heti_css}
    #{heti_js}
    """
  end

  defp get_route(item), do: @static_index[item] |> (fn {route, _} -> route end).()
end
