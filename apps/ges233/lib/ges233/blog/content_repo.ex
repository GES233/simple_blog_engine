defmodule GES233.Blog.ContentRepo do
  @moduledoc """
  负责保存可能出现的大容量数据。

  为了方便管理作为单独的进程。
  """
  require Logger

  use GenServer
  @threshold 2000

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def cache_raw(content, id) do
    GenServer.call(__MODULE__, {:cache, {content, id, :raw}})
  end

  def cache_html(html, id) do
    GenServer.call(__MODULE__, {:cache, {html, id, :html}})
  end

  def get_raw(id) do
    GenServer.call(__MODULE__, {:get, {id, :raw}})
  end

  def get_html(id) do
    GenServer.call(__MODULE__, {:get, {id, :html}})
  end

  @impl GenServer
  def init(_enable_options) do
    name = :ets.new(:content_repo, [:set, :public, :named_table])

    ref = %{}

    Logger.info("ContentRepo Created...")

    {:ok, {name, ref}}
  end

  def enough_large?(content) do
    String.length(content) >= @threshold
  end

  @impl true
  def handle_call({:cache, {content, id, format}}, _from, state) do
    # 存入 ETS 表
    :ets.insert(:content_repo, {{id, format}, content})

    {:reply, {:ref, id}, state}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    case :ets.lookup(:content_repo, key) do
      [{^key, content}] ->
        {:reply, {:ok, content}, state}

      [] ->
        {:reply, {:error, :not_found}, state}
    end
  end
end
