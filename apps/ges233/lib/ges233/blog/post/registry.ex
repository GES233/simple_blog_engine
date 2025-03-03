defmodule GES233.Blog.Post.Registry do
  # ...
end

defmodule GES233.Blog.Post.ContentRepo do
  @moduledoc """
  负责保存可能出现的大容量数据。

  为了方便管理作为单独的进程。
  """
  # https://hexdocs.pm/elixir/main/erlang-term-storage.html

  use GenServer
  @threshold 5000

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [])
  end

  @impl GenServer
  def init(_init_arg) do
    name = :ets.new(__MODULE__, [:named_table])

    {:ok, {name, %{}}}
  end

  def enough_large?(content) do
    String.length(content) >= @threshold
  end

  def put() do
    # ...
  end

  def get() do
    # ...
  end
end
