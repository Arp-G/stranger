defmodule StrangerWeb.ChatComponent do
  use Phoenix.LiveComponent
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
          <li id="chat-<%= message.id %>">
          <strong> <%= message.name %> </strong>
          <br>
          <p>
            <%= message.content %>
          </p>
          <br>
          <br>
          </li>
        <% end %>
      </ul>

      <%= f = form_for @message_changeset, "#", [phx_submit: :send_message, class: "chat_input"] %>

        <p> <%= text_input f, :content %> <%= submit "Save", "phx-disable-with": "Sending...", class: "btn btn-primary" %> </p>
      </form>
    </div>
    """
  end
end
