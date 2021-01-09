defmodule Stranger.RoomMaster do
  @moduledoc """
  state:
  %{
    rooms: [
      %{
        id: "123",
        users: [
          %{
            id: "5feb60a50bbd4a581689424b",
            token: "abcdefg",
            pid: liveview_pid,
            stream_id: "asdf1234",
            created_at: ~U[2021-01-08 20:24:47.914000Z]
          }
        ]
      }
    ]
  }
  """
  use GenServer

  require Logger

  @cleanup_job_interval 60000
  # 1hr
  @max_room_duration 3600

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def join_room(room_id, user_id, pid) do
    GenServer.call(__MODULE__, {:join_room, room_id, user_id, pid})
  end

  def store_stream_id(room_id, user_id, stream_id) do
    GenServer.call(__MODULE__, {:store_stream_id, room_id, user_id, stream_id})
  end

  def leave_room(room_id) do
    GenServer.call(__MODULE__, {:end_meet, room_id})
  end

  def init(:ok) do
    Process.send_after(self(), :cleanup_job, 0)
    {:ok, %{rooms: []}}
  end

  def handle_info(:cleanup_job, %{rooms: rooms}) do
    IO.inspect("Cleanup job running")

    rooms =
      rooms
      |> Enum.reject(fn %{users: users, created_at: created_at} = room ->
        time_up =
          created_at
          |> DateTime.add(@max_room_duration)
          |> DateTime.compare(DateTime.utc_now())
          |> case do
            :gt -> true
            :lt -> false
          end

        if time_up || Enum.any?(users, &(!Process.alive?(&1.pid))) do
          IO.inspect("Rejecting room #{room.id}")
          GenServer.call(__MODULE__, {:end_meet, room.id})
          true
        else
          false
        end
      end)

    Process.send_after(self(), :cleanup_job, @cleanup_job_interval) # ERROR ! (EXIT) process attempted to call itself

    {:noreply, %{rooms: rooms}}
  end

  def handle_call({:join_room, room_id, user_id, live_view_pid}, _, %{rooms: rooms} = state) do
    {%{users: existing_users, session_id: session_id} = room, other_rooms} =
      get_or_create_room(rooms, room_id)

    if Enum.count(existing_users) < 2 do
      existing_users
      |> Enum.find(&(&1.id == user_id))
      |> case do
        nil ->
          Logger.info("adding #{user_id} to #{room_id}")
          token = ExOpentok.Token.generate(session_id)

          users = [
            %{id: user_id, pid: live_view_pid, token: token, stream_id: nil} | existing_users
          ]

          room = %{room | users: users}

          # Send room updates to all connected live views
          Enum.each(existing_users, fn %{pid: live_view_pid} ->
            send(live_view_pid, {:room_updated, room})
          end)

          rooms = [room | other_rooms]
          {:reply, {:ok, room}, %{state | rooms: rooms}}

        _ ->
          {:reply, {:error, "user already in room"}, %{state | rooms: rooms}}
      end
    else
      {:reply, {:error, "Room full"}, state}
    end
  end

  def handle_call({:store_stream_id, room_id, user_id, stream_id}, _, %{rooms: rooms} = state) do
    {[%{users: users} = room], other_rooms} = Enum.split_with(rooms, &(&1.id == room_id))

    users =
      Enum.map(users, fn
        %{id: ^user_id} = user -> %{user | stream_id: stream_id}
        user -> user
      end)

    room = %{room | users: users}
    Enum.each(users, &send(&1.pid, {:room_updated, room}))

    {:reply, :ok, %{state | rooms: [room | other_rooms]}}
  end

  def handle_call({:end_meet, room_id}, _, %{rooms: rooms} = state) do
    IO.puts("Terminate callback handled")

    case Enum.find(rooms, &(&1.id == room_id)) do
      %{users: users} ->
        Enum.each(users, &send(&1.pid, :end_meeting))

        {:noreply, :ok, %{state | rooms: Enum.reject(rooms, &(&1.id == room_id))}}

      nil ->
        {:noreply, state}
    end
  end

  defp get_or_create_room(rooms, room_id) do
    rooms
    |> Enum.split_with(&(&1.id == room_id))
    |> case do
      {[], _} ->
        Logger.info("creating room #{room_id}")
        session_id = generate_session_id()
        Stranger.Conversations.update_conversation_with_session(room_id, session_id)

        {%{id: room_id, users: [], session_id: session_id, created_at: DateTime.utc_now()}, rooms}

      {[room], other_rooms} ->
        {room, other_rooms}
    end
  end

  defp generate_session_id do
    %{"session_id" => session_id} = ExOpentok.init()
    session_id
  end
end
