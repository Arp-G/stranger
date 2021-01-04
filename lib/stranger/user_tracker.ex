defmodule Stranger.UserTracker do
  use GenServer

  @topic "active_users"
  @user_types [:active_users, :searching_users]

  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_args, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{active_users: MapSet.new(), searching_users: MapSet.new()}}
  end

  def get_active_users_count() do
    GenServer.call(__MODULE__, :get_active_users_count, :infinity)
  end

  def add_user(user_id, type) when type in @user_types do
    GenServer.cast(__MODULE__, {:add_user, type, user_id})
  end

  def remove_user(user_id, type) when type in @user_types do
    GenServer.cast(__MODULE__, {:remove_user, type, user_id})
  end

  def get_match_for_user(user_id) do
    GenServer.call(__MODULE__, :get_searching_users, :infinity)
    |> MapSet.difference(MapSet.new([user_id]))
    |> Enum.take(1)
    |> case do
      [matched_user_id] ->
        GenServer.call(__MODULE__, {:remove_matched_users, user_id, matched_user_id}, :infinity)
        IO.inspect("Returning #{inspect(matched_user_id)}")
        matched_user_id

      _ ->
        nil
    end
  end

  def handle_cast({:add_user, user_type, user_id}, state) when user_type in @user_types do
    users = MapSet.put(state[user_type], user_id)
    if user_type == :active_users, do: broadcast_active_users_count(users)
    {:noreply, Map.put(state, user_type, users)}
  end

  def handle_cast({:remove_user, user_type, user_id}, state) when user_type in @user_types do
    users = MapSet.delete(state[user_type], user_id)
    if user_type == :active_users, do: broadcast_active_users_count(users)
    {:noreply, Map.put(state, :searching_users, users)}
  end

  def handle_call(:get_active_users_count, _from, %{active_users: active_users} = state) do
    {:reply, Enum.count(active_users), state}
  end

  def handle_call(:get_searching_users, _from, %{searching_users: searching_users} = state) do
    {:reply, searching_users, state}
  end

  def handle_call(
        {:remove_matched_users, user_1, user_2},
        _from,
        %{searching_users: searching_users} = state
      ) do
    users =
      searching_users
      |> MapSet.delete(user_1)
      |> MapSet.delete(user_2)

    {:noreply, Map.put(state, :searching_users, users)}
  end

  defp broadcast_active_users_count(state) do
    Phoenix.PubSub.broadcast!(Stranger.PubSub, @topic, Enum.count(state))
  end
end
