defmodule StrangerWeb.MessagesLive do
  use StrangerWeb, :live_view
  alias Stranger.{Accounts, Conversations, Messages}

  @impl Phoenix.LiveView
  def mount(
        %{"conversation_id" => conversation_id} = _params,
        session,
        socket
      ) do
    socket = assign_defaults(socket, session)

    conversation_id = BSON.ObjectId.decode!(conversation_id)
    messages = Messages.list_messages_for_conversation(conversation_id)

    stranger =
      conversation_id
      |> Conversations.get_stranger_for_conversation(socket.assigns.user._id)
      |> Accounts.get_user()

    {:ok,
     assign(socket,
       count: Messages.get_messages_count(conversation_id),
       messages: messages,
       page: 1,
       conversation: Conversations.get_conversation(conversation_id),
       stranger: stranger
     )}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~L"""
    <div class="alert alert-primary" role="alert">
      <%= "You matched with #{@stranger.profile.first_name} on #{Calendar.strftime(assigns.conversation.started_at, "%A, %B %d %Y")}" %>
      <br>
      <%= "There are #{@count} messages in this conversation" %>
    </div>
    <%= live_component @socket, StrangerWeb.UserProfileComponent, user: @stranger %>
    <br>
    <%= if !Enum.empty?(@messages) do %>
      <div class="form_heading"> Messages </div>
      <div phx-hook="InfiniteScroll" id="inifinite-scroll" class="messages-container">
        <%= for message <- @messages do %>
          <div id="chat-<%= message._id %>" class="<%= get_msg_bubble_class(message, @user) %>">
            <small class="message-sender"> <%= get_sender_name(message, @user, @stranger) %> </small>
            <p>
              <%= message.content %>
            </p>
          </div>
        <% end %>
      </div>
    <% end %>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {
      :noreply,
      socket
      |> assign(page: assigns.page + 1)
      |> fetch_more_messages()
    }
  end

  defp fetch_more_messages(%{assigns: assigns} = socket) do
    assign(socket,
      messages:
        assigns.messages ++
          Messages.list_messages_for_conversation(assigns.conversation._id, assigns.page)
    )
  end

  defp get_sender_name(message, user, stranger) do
    sender = if message.sender_id == user._id, do: user, else: stranger

    sender.profile.first_name
  end

  defp get_msg_bubble_class(message, user) do
    if message.sender_id == user._id, do: "bubble bubble-bottom-left", else: "bubble bubble-bottom-right"
  end
end
