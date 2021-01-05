defmodule StrangerWeb.RoomLive do
  use StrangerWeb, :live_view

  alias Stranger.RoomMaster

  @impl Phoenix.LiveView
  def mount(%{"room_id" => room_id, "user_id" => user_id} = _params, _session, socket) do
    socket =
      socket
      |> assign(:user_id, user_id)
      |> assign(:room_id, room_id)
      |> assign(:room, nil)

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
  end

  @impl Phoenix.LiveView
  def handle_info({:room_updated, room}, socket) do
    {:noreply, assign(socket, :room, room)}
  end

  @impl Phoenix.LiveView
  def handle_event("get_publish_info", _, socket) do
    %{token: token} = get_me(socket)
    {:reply, %{key: get_key(), token: token, session_id: socket.assigns.room.session_id}, socket}
  end

  def handle_event("store_stream_id", %{"stream_id" => stream_id}, socket) do
    RoomMaster.store_stream_id(socket.assigns.room_id, socket.assigns.user_id, stream_id)
    {:noreply, socket}
  end

  defp get_key, do: Application.fetch_env!(:ex_opentok, :key)

  def get_me(%{assigns: %{room: room, user_id: user_id}}), do: user_in_room(room, user_id)

  defp user_in_room(%{users: users}, user_id), do: Enum.find(users, &(&1.id == user_id))

  defp others_in_room(%{users: users}, user_id), do: Enum.reject(users, &(&1.id == user_id))
end
