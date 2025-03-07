defmodule GES233.Blog.SimpleServer do
  # Usage: Bandit.start_link(plug: GES233.Blog.SimpleServer)
  use Plug.Builder

  plug(Plug.Logger)
  plug(:redirect_index)
  plug(GES233.Blog.SimpleServer.HTMLServer)
  plug(Plug.Static, at: "/", from: "#{Application.compile_env(:ges233, :saved_path)}/")
  plug(:not_found)

  def redirect_index(%Plug.Conn{path_info: path} = conn, _opts) do
    case path |> Enum.filter(&String.contains?(&1, ".")) do
      [] ->
        %{conn | path_info: path ++ ["index.html"]}

      _ ->
        conn
    end
  end

  def not_found(conn, _) do
    send_resp(conn, 404, "not found")
  end
end
