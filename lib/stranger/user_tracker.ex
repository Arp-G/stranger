defmodule Stranger.UserTracker do
  use GenServer

  @topic "active_users"
  @user_types [:active_users, :searching_users]
  # Search for a match every 500ms
  @match_search_interval 500

  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_args, name: __MODULE__)
  end

  def init(_) do
    Process.send_after(self(), :matching, 1000)
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

  def handle_cast({:add_user, user_type, user_id}, state) when user_type in @user_types do
    users = MapSet.put(state[user_type], user_id)
    if user_type == :active_users, do: broadcast_active_users_count(users)
    {:noreply, Map.put(state, user_type, users)}
  end

  def handle_cast({:remove_user, user_type, user_id}, state) when user_type in @user_types do
    users = MapSet.delete(state[user_type], user_id)
    if user_type == :active_users, do: broadcast_active_users_count(users)
    {:noreply, Map.put(state, user_type, users)}
  end

  def handle_call(:get_active_users_count, _from, %{active_users: active_users} = state) do
    {:reply, Enum.count(active_users), state}
  end

  def handle_info(:matching, %{searching_users: searching_users} = state) do
    Process.send_after(self(), :matching, @match_search_interval)

    searching_users
    |> Enum.shuffle()
    |> Enum.take(2)
    |> case do
      [user_1, user_2] ->
        users =
          searching_users
          |> MapSet.delete(user_1)
          |> MapSet.delete(user_2)

        Phoenix.PubSub.broadcast!(Stranger.PubSub, @topic, {:matched, [user_1, user_2]})
        {:noreply, Map.put(state, :searching_users, users)}

      _ ->
        {:noreply, state}
    end
  end

  defp broadcast_active_users_count(state) do
    Phoenix.PubSub.broadcast!(
      Stranger.PubSub,
      @topic,
      {:active_users, Enum.count(state)}
    )
  end
end
