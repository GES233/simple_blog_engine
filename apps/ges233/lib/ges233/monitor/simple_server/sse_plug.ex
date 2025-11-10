defmodule GES233.SimpleServer.SSEPlug do
  use Plug.Builder
  alias GES233.Broadcaster

  def init(opts), do: opts

  def call(conn, _opts) do
    conn =
      conn
      |> put_resp_header("Content-Type", "text/event-stream")
      |> put_resp_header("Cache-Control", "no-cache")
      |> put_resp_header("Connection", "keep-alive")
      |> send_chunked(200)

    # Subscribe to broadcasts
    Broadcaster.subscribe()

    # Enter a loop to wait for messages and send them to the client
    loop_and_send(conn)
  end

  defp loop_and_send(conn) do
    receive do
      # We expect a :reload message from the Broadcaster
      {:reload, data} ->
        payload = format_sse("reload", data)

        case Plug.Conn.chunk(conn, payload) do
          {:ok, conn} ->
            loop_and_send(conn)
          {:error, :closed} ->
            # Client has disconnected, we are done.
            conn
        end
    after
      # Send a comment every 25 seconds to keep the connection alive
      25_000 ->
        case Plug.Conn.chunk(conn, ": keepalive\n\n") do
          {:ok, conn} ->
            loop_and_send(conn)
          {:error, :closed} ->
            conn
        end
    end
  end

  # Format message according to the SSE spec
  defp format_sse(event, data) do
    """
    event: #{event}
    data: #{Jason.encode!(data)}

    """
  end
end
