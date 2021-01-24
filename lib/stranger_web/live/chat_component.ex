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
    <div id="chat_box" class="<%= @chat_box %>" phx-hook="OnNewChatMsg">
      <button phx-click="chat_box_toggle" class="chat_header">
        <%= if @unread_messages do %>
          <div class="blinking"></div>
        <% end %>
        <span> Chat </span>
      </button>
      <div class="chat_messages_<%= @chat_box %>">
        <%= for message <- Enum.reverse(@messages) do %>
          <div id="chat-<%= message.id %>" class="<%= get_msg_bubble_class(message, @user) %> small-bubble">
            <small class="message-sender"> <%= get_sender_name(message, @user, @stranger) %> </small>
            <div class="chat-content">
              <%= message.content %>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    <%= f = form_for @message_changeset, "#", [phx_submit: :send_message, class: "chat_input chat_input_#{@chat_box}"] %>
      <div class="form-group">
        <%= text_input f, :content, class: "form-control" %>
        <%= submit "phx-disable-with": "Sending...", class: "btn btn-primary" do %>
          <i class="fa fa-paper-plane" aria-hidden="true"></i>
        <% end %>
      </div>
    </form>
    """
  end
end
