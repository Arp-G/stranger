defmodule StrangerWeb.ChatComponent do
  use StrangerWeb, :live_component
  use Phoenix.HTML

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~L"""
    <div id="chat_box" class="<%= @chat_box %>">
    <button phx-click="chat_box_toggle" class="chat_header"> Chat <%= @unread_messages %></button>
      <ul id="messages">
        <%= for message <- Enum.reverse(@messages) do %>
          <div id="chat-<%= message.id %>" class="<%= get_msg_bubble_class(message, @user) %> small-bubble">
            <small class="message-sender"> <%= get_sender_name(message, @user, @stranger) %> </small>
            <div class="chat-content">
              <%= message.content %>
            </div>
          </div>
        <% end %>
      </ul>

      <%= f = form_for @message_changeset, "#", [phx_submit: :send_message, class: "chat_input"] %>
        <p> <%= text_input f, :content %> <%= submit "Save", "phx-disable-with": "Sending...", class: "btn btn-primary" %> </p>
      </form>
    </div>
    """
  end
end
