defmodule GES233.Blog.SimpleServer.HTMLServer do
  use Plug.Builder

  def init(opts) do
    opts
  end

  def call(%Plug.Conn{path_info: path} = conn, _opts) do
    cond do
      "index.html" in path ->
        html =
          "#{Application.get_env(:ges233, :saved_path) |> Path.absname()}/#{Enum.join(path, "/")}"
          |> File.read!()

        conn
        |> put_resp_content_type("text/html; charset=utf-8")
        |> resp(200, html)
        |> halt()

      true ->
        conn
    end
  end
end
