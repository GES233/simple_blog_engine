defmodule GES233.Blog.SimpleServer do
  use Plug.Builder

  plug(Plug.Static, at: "/priv/source", from: :ges233)
end
