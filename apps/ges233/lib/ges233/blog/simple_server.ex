defmodule GES233.Blog.SimpleServer do
  # Usage: Bandit.start_link(plug: GES233.Blog.SimpleServer)
  use Plug.Builder

  plug(Plug.Logger)
  plug(:sse_handler)
  plug(:redirect_index)
  plug(GES233.Blog.SimpleServer.HTMLServer)
  plug(Plug.Static, at: "/", from: "#{Application.compile_env(:ges233, :saved_path)}/")
  plug(:not_found)

  defp sse_handler(conn, _opts) do
    if conn.path_info == ["sse"] do
      # 如果路径是 /sse，交给 SSEPlug 处理并停止后续处理
      GES233.Blog.SimpleServer.SSEPlug.call(conn, []) |> halt()
    else
      # 否则，继续处理管道中的下一个 plug
      conn
    end
  end

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
