defmodule StrangerWeb.DashboardLive do
  use StrangerWeb, :live_view
  use Phoenix.HTML
  alias Stranger.UserTracker
  alias StrangerWeb.LiveHelpers

  @topic "active_users"

  @impl true
  def mount(_params, %{"token" => token} = _session, socket) do
    StrangerWeb.Endpoint.subscribe(@topic)

    with {:ok, user_id} <- StrangerWeb.UserAuth.get_user_id(token) do
      UserTracker.add_user(user_id, :active_users)

      {:ok,
       assign(socket,
         user_id: user_id,
         status: :idle,
         active_users: UserTracker.get_active_users_count()
       )}
    end
  end

  @impl true
  def handle_event("search", _args, %{assigns: %{user_id: user_id}} = socket) do
    UserTracker.add_user(user_id, :searching_users)
    {:noreply, assign(socket, status: :searching)}
  end

  @impl true
  def handle_event("stop_search", _args, %{assigns: %{user_id: user_id}} = socket) do
    UserTracker.remove_user(user_id, :searching_users)
    {:noreply, assign(socket, status: :idle)}
  end

  @impl true
  def handle_info({:active_users, active_users}, socket) do
    {:noreply, assign(socket, active_users: active_users)}
  end

  @impl true
  def handle_info({:matched, [user_1, user_2]}, %{assigns: %{user_id: user_id}} = socket) do
    if user_id in [user_1, user_2] do
      matched_user = if(user_id == user_1, do: user_2, else: user_1)
      Process.send_after(self(), {:redirect_after_match, matched_user}, 3000)
      {:noreply, assign(socket, status: {:matched, matched_user})}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:redirect_after_match, matched_user}, %{assigns: %{user_id: user_id}} = socket) do
    socket =
      push_redirect(socket,
        to:
          Routes.room_path(
            socket,
            :index,
            get_room_name(user_id, matched_user),
            BSON.ObjectId.encode!(socket.assigns.user_id)
          )
      )

    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, %{assigns: %{user_id: user_id}} = _socket) do
    UserTracker.remove_user(user_id, :active_users)
  end

  defp dashboard_status(status) do
    case status do
      :searching ->
        ~E"""
          Searching...
          <button class="btn btn-primary" phx-click="stop_search">Stop Searching</button>
        """

      {:matched, matched_user_id} ->
        ~E"""
          Found a match with <%= inspect(matched_user_id) %>
        """

      _ ->
        ~E"""
        <button class="btn btn-primary" phx-click="search">Start Searching</button>
        """
    end
  end
end
