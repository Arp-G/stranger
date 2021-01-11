defmodule StrangerWeb.ConversationsLive do
  use StrangerWeb, :live_view
  use Phoenix.HTML
  alias Stranger.Conversations

  @impl Phoenix.LiveView
  def mount(_params, %{"token" => token} = _session, socket) do
    {:ok, user_id} = StrangerWeb.UserAuth.get_user_id(token)

    {:ok,
     assign(socket,
       user_id: user_id,
       conversations: Conversations.get_conversations(user_id)
     )}
  end
end
