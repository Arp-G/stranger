defmodule StrangerWeb.ConversationsLive do
  use StrangerWeb, :live_view
  use Phoenix.HTML
  alias Stranger.Conversations

  @impl Phoenix.LiveView
  def mount(_params, %{"token" => token} = _session, socket) do
    {:ok, user_id} = StrangerWeb.Plugs.UserAuth.get_user_id(token)

    {:ok,
     assign(socket,
       user_id: user_id,
       conversations: Conversations.get_conversations(user_id),
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
        assigns.conversations ++ Conversations.get_conversations(assigns.user_id, assigns.page)
    )
  end
end
