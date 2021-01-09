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
    <div id="chat_box">
      <ul id="messages">
        <%= for message <- @messages do %>
          <li id=<%= "chat" %>>
          <strong> Sender: </strong> <%= message.sender_id %>
          <br>
          <p>
            <%= message.content %>
          </p>
          <br>
          <br>
          </li>
        <% end %>
      </ul>

      <%= f = form_for @message_changeset, "#", [phx_submit: :send_message] %>
        <p> <%= text_input f, :content %> </p>
        <p> <%= submit "Save", "phx-disable-with": "Sending...", class: "btn btn-primary" %> </p>
      </form>
    </div>
    """
  end
end

# ~L"""
# <div id="chat_box">
#   <ul id="messages">
#     <%= for message <- @messages do %>
#       <li id=<%= "chat" %>>
#         <%= inspect message %>
#       </li>
#     <% end %>
#   </ul>

#   <%= f = form_for @message_changeset, "#", [phx_submit: :send_message] %>
#     <p> <%= text_input f, :content %> </p>
#     <p> <%= submit "Save", "phx-disable-with": "Sending...", class: "btn btn-primary" %> </p>
#   </form>
# </div>
# """
# <strong> Sender: </strong> <%= message.sender_id %>
# <br>
# <p>
#   <%= message.content %>
# </p>
# <br>
# <br>
