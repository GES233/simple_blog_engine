defmodule GES233.Broadcaster do
  use GenServer
  require Logger

  # ==================================================================
  # Public API
  # ==================================================================

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, MapSet.new(), name: __MODULE__)
  end

  @doc "Subscribe the calling process to receive broadcast messages."
  def subscribe do
    # We use call to ensure the subscription is confirmed before proceeding.
    GenServer.call(__MODULE__, {:subscribe, self()})
  end

  @doc "Broadcast a message to all subscribers."
  def broadcast(message) do
    # Cast is fine here; we don't need to wait for a reply.
    GenServer.cast(__MODULE__, {:broadcast, message})
  end

  # ==================================================================
  # GenServer Callbacks
  # ==================================================================

  @impl true
  def init(subscribers) do
    Logger.info("SSE Broadcaster started.")
    {:ok, subscribers}
  end

  @impl true
  def handle_call({:subscribe, pid}, _from, subscribers) do
    # Monitor the subscriber process. If it dies, we'll get a :DOWN message.
    Process.monitor(pid)
    new_subscribers = MapSet.put(subscribers, pid)
    Logger.debug("New SSE subscriber: #{inspect(pid)}. Total: #{MapSet.size(new_subscribers)}")
    {:reply, :ok, new_subscribers}
  end

  @impl true
  def handle_cast({:broadcast, message}, subscribers) do
    # Send the message to every subscribed process.
    Enum.each(subscribers, fn pid ->
      send(pid, message)
    end)
    {:noreply, subscribers}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, subscribers) do
    # A subscriber has disconnected. Remove it from our list.
    new_subscribers = MapSet.delete(subscribers, pid)
    Logger.debug("SSE subscriber disconnected: #{inspect(pid)}. Total: #{MapSet.size(new_subscribers)}")
    {:noreply, new_subscribers}
  end
end
