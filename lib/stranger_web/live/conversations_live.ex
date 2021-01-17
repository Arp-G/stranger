defmodule StrangerWeb.ConversationsLive do
  use StrangerWeb, :live_view
  use Phoenix.HTML
  alias Stranger.Conversations

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    socket = assign_defaults(socket, session)

    {:ok,
     socket
     |> assign(
       count: Conversations.get_conversations_count(socket.assigns.user._id),
       conversations: Conversations.get_conversations(socket.assigns.user._id),
       page: 1
     )}
  end

  @impl Phoenix.LiveView
  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {
      :noreply,
      socket
      |> assign(page: assigns.page + 1)
      |> fetch_more_conversations()
    }
  end

  defp fetch_more_conversations(%{assigns: assigns} = socket) do
    assign(socket,
      conversations:
        assigns.conversations ++ Conversations.get_conversations(assigns.user._id, assigns.page)
    )
  end
end
