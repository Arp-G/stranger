defmodule StrangerWeb.DashboardLive do
  use StrangerWeb, :live_view
  use Phoenix.HTML
  alias Stranger.ActiveUserTracker

  @topic "active_users"

  @impl true
  def mount(_params, %{"token" => token} = _session, socket) do
    StrangerWeb.Endpoint.subscribe(@topic)

    with {:ok, user_id} <- StrangerWeb.UserAuth.get_user_id(token) do
      Stranger.ActiveUserTracker.add_user(user_id)
      {:ok, assign(socket, user_id: user_id, active_users: ActiveUserTracker.get_active_users())}
    end
  end

  @impl true
  def handle_info(active_users, socket) do
    {:noreply, assign(socket, active_users: active_users)}
  end

  @impl true
  def terminate(_reason, %{assigns: %{user_id: user_id}} = _socket) do
    ActiveUserTracker.remove_user(user_id)
  end
end

# p = "live_view_upload-1609522426-906582229084086-5"
# Avatar.url({user.profile.avatar, user}, signed: true)
