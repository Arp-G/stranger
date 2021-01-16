defmodule StrangerWeb.RoomLive do
  use StrangerWeb, :live_view
  alias Stranger.{RoomMaster, Accounts, Messages, Messages.Message}

  @impl Phoenix.LiveView
  def mount(%{"conversation_id" => room_id} = _params, %{"token" => token} = _session, socket) do
    {:ok, user_id} = StrangerWeb.Plugs.UserAuth.get_user_id(token)
    room_id = BSON.ObjectId.decode!(room_id)

    socket =
      assign(socket,
        user: Accounts.get_user(user_id),
        user_id: user_id,
        room_id: room_id,
        room: nil,
        stranger: nil,
        message_changeset: Message.changeset(%{}),
        messages: [],
        unread_messages: false,
        chat_box: "close"
      )

    room_id
    |> get_message_topic()
    |> StrangerWeb.Endpoint.subscribe()

    case RoomMaster.join_room(room_id, user_id, self()) do
      {:ok, room} ->
        {:ok, assign(socket, room: room)}

      {:error, reason} ->
        {:ok, socket |> put_flash(:error, reason) |> redirect(to: "/dashboard")}
    end
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
  def handle_event("chat_box_toggle", %{}, socket) do
    updated_assigns =
      if socket.assigns.chat_box == "close" do
        [chat_box: "open", unread_messages: false]
      else
        [chat_box: "close"]
      end

    {:noreply, assign(socket, updated_assigns)}
  end

  @impl Phoenix.LiveView
  def handle_event("leave_room", _attrs, socket) do
    RoomMaster.leave_room(socket.assigns.room_id)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "send_message",
        %{"message" => %{"content" => message}},
        %{assigns: assigns} = socket
      ) do
    message = %{
      id: nil,
      name: nil,
      conversation_id: assigns.room_id,
      sender_id: assigns.user_id,
      content: message
    }

    message
    |> Messages.create_message()
    |> case do
      {:ok,
       %Mongo.InsertOneResult{
         acknowledged: true,
         inserted_id: id
       }} ->
        Phoenix.PubSub.broadcast!(
          Stranger.PubSub,
          get_message_topic(assigns.room_id),
          {:got_message, %{message | id: id, name: get_user_name(socket)}}
        )

      _ ->
        nil
    end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:room_updated, room}, socket) do
    socket = assign(socket, :room, room)

    if is_nil(socket.assigns.stranger) && Enum.count(room.users) == 2 do
      [user1, user2] = room.users

      stranger =
        if(socket.assigns.user_id == user1.id, do: user2.id, else: user1.id)
        |> Accounts.get_user()

      {:noreply, assign(socket, :stranger, stranger)}
    else
      {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:end_meeting, reason}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, reason)
     |> redirect(to: "/dashboard")}
  end

  @impl Phoenix.LiveView
  def handle_info({:got_message, message}, socket) do
    {:noreply,
     assign(socket,
       messages: [message | socket.assigns.messages],
       unread_messages: socket.assigns.chat_box == "close"
     )}
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

  defp get_message_topic(room_id) do
    "room_chat:#{room_id}"
  end

  defp get_user_name(%{assigns: %{user: %{profile: %{first_name: fname, last_name: lname}}}}) do
    "#{fname} #{lname}"
  end
end
