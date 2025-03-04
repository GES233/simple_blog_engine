defmodule GES233.Blog.Post.Registry do
  # ...
end

defmodule GES233.Blog.Post.ContentRepo do
  @moduledoc """
  负责保存可能出现的大容量数据。

  为了方便管理作为单独的进程。
  """
  require Logger

  # https://hexdocs.pm/elixir/main/erlang-term-storage.html

  use GenServer
  @threshold 5000

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [])
  end

  @impl GenServer
  def init(_enable_options) do
    name = :ets.new(__MODULE__, [:named_table])

    ref = %{}

    Logger.info("ContentRepo Created...")

    {:ok, {name, ref}}
  end

  def lookup(name) do
    case :ets.lookup(__MODULE__, name) do
      [{^name, pid}] -> {:ok, pid}
      [] -> :error
    end
  end

  def enough_large?(content) do
    String.length(content) >= @threshold
  end

  def put(id, format, content) do
    :ets.insert(__MODULE__, {{id, format}, content})
  end

  def get() do
    # ...
  end
end
