defmodule Stranger.ActiveUserTracker do
  use GenServer

  @topic "active_users"

  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_args, name: __MODULE__)
  end

  def init(_) do
    {:ok, MapSet.new()}
  end

  def get_active_users() do
    GenServer.call(__MODULE__, :get_active_users, :infinity)
  end

  def add_user(user_id) do
    GenServer.cast(__MODULE__, {:add_user, user_id})
  end

  def remove_user(user_id) do
    GenServer.cast(__MODULE__, {:remove_user, user_id})
  end

  def handle_cast({:add_user, user_id}, state) do
    state = MapSet.put(state, user_id)
    broadcast_active_users_count(state)
    {:noreply, state}
  end

  def handle_cast({:remove_user, user_id}, state) do
    state = MapSet.delete(state, user_id)
    broadcast_active_users_count(state)
    {:noreply, state}
  end

  def handle_call(:get_active_users, _from, state) do
    {:reply, Enum.count(state), state}
  end

  defp broadcast_active_users_count(state) do
    Phoenix.PubSub.broadcast!(Stranger.PubSub, @topic, Enum.count(state))
  end
end
