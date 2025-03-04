defmodule GES233.Blog.SimpleServer do
  use Plug.Builder

  plug(Plug.Static, at: "/priv/_page/", from: :ges233)
  plug(:not_found)

  def not_found(conn, _) do
    send_resp(conn, 404, "not found")
  end
end
