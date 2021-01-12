defmodule StrangerWeb.MessagesLive do
  use StrangerWeb, :live_view
  alias Stranger.{Accounts, Conversations, Messages}

  @impl Phoenix.LiveView
  def mount(
        %{"conversation_id" => conversation_id} = _params,
        %{"token" => token} = _session,
        socket
      ) do
    {:ok, user_id} = StrangerWeb.UserAuth.get_user_id(token)

    conversation_id = BSON.ObjectId.decode!(conversation_id)
    messages = Messages.list_messages_for_conversation(conversation_id)

    stranger =
      conversation_id
      |> Conversations.get_stranger_for_conversation(user_id)
      |> Accounts.get_user()

    {:ok,
     assign(socket, messages: messages, user: Accounts.get_user(user_id), stranger: stranger)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~L"""
    <div>
      <%= inspect @stranger %>
    </div>
    <div id="chat_box">
      <ul id="messages">
        <%= for message <- @messages do %>
          <li id="chat-<%= message._id %>">
          <strong> <%= get_sender_name(message, @user, @stranger) %> </strong>
          <br>
          <p>
            <%= message.content %>
          </p>
          <br>
          <br>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  defp get_sender_name(message, user, stranger) do
    sender = if message.sender_id == user._id, do: user, else: stranger

    "#{sender.profile.first_name} #{sender.profile.last_name}"
  end
end
