defmodule StrangerWeb.RoomLive do
  use StrangerWeb, :live_view

  alias Stranger.RoomMaster

  @impl Phoenix.LiveView
  def mount(%{"room_id" => room_id, "user_id" => user_id} = _params, _session, socket) do
    user_id = BSON.ObjectId.decode!(user_id)
    room_id = BSON.ObjectId.decode!(room_id)

    socket =
      socket
      |> assign(:user_id, user_id)
      |> assign(:room_id, room_id)
      |> assign(:room, nil)

    if Stranger.Conversations.check_if_user_belongs_to_conversation(user_id, room_id) do
      if connected?(socket) do
        case RoomMaster.join_room(room_id, user_id, self()) do
          {:ok, room} ->
            {:ok, assign(socket, :room, room)}

          {:error, reason} ->
            {:ok, socket |> put_flash(:error, reason) |> redirect(to: "/dashboard")}
        end
      else
        {:ok, socket}
      end
    else
      {
        :ok,
        socket
        |> put_flash(:error, "You are not allowed to join this room")
        |> redirect(to: "/dashboard")
      }
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:room_updated, room}, socket) do
    {:noreply, assign(socket, :room, room)}
  end

  @impl Phoenix.LiveView
  def handle_info({:end_meeting, reason}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, reason)
     |> redirect(to: "/dashboard")}
  end

  @impl Phoenix.LiveView
  def handle_event("get_publish_info", _, socket) do
    %{token: token} = get_me(socket)
    {:reply, %{key: get_key(), token: token, session_id: socket.assigns.room.session_id}, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("store_stream_id", %{"stream_id" => stream_id}, socket) do
    RoomMaster.store_stream_id(socket.assigns.room_id, socket.assigns.user_id, stream_id)
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def terminate(_reason, %{assigns: %{room_id: room_id}} = _socket) do
    RoomMaster.leave_room(room_id)
  end

  defp get_key, do: Application.fetch_env!(:ex_opentok, :key)

  def get_me(%{assigns: %{room: room, user_id: user_id}}), do: user_in_room(room, user_id)

  defp user_in_room(%{users: users}, user_id), do: Enum.find(users, &(&1.id == user_id))

  defp stranger_in_room(%{users: users}, user_id),
    do: Enum.reject(users, &(&1.id == user_id)) |> List.first()
end
