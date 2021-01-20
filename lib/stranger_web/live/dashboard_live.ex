defmodule StrangerWeb.DashboardLive do
  use StrangerWeb, :live_view
  use Phoenix.HTML
  alias Stranger.{UserTracker, Accounts}

  @topic "active_users"

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    socket = assign_defaults(socket, session)

    StrangerWeb.Endpoint.subscribe(@topic)
    UserTracker.add_user(socket.assigns.user._id, :active_users)

    {:ok,
     socket
     |> assign(
       status: :idle,
       active_users: UserTracker.get_active_users_count(),
       stranger: nil
     )}
  end

  @impl Phoenix.LiveView
  def handle_event("search", _args, %{assigns: %{user: user}} = socket) do
    UserTracker.add_user(user._id, :searching_users)
    {:noreply, assign(socket, status: :searching)}
  end

  @impl Phoenix.LiveView
  def handle_event("stop_search", _args, %{assigns: %{user: user}} = socket) do
    UserTracker.remove_user(user._id, :searching_users)
    {:noreply, assign(socket, status: :idle)}
  end

  @impl Phoenix.LiveView
  def handle_info({:active_users, active_users}, socket) do
    {:noreply, assign(socket, active_users: active_users)}
  end

  @impl Phoenix.LiveView
  def handle_info(
        {:matched, [user_1, user_2, conversation_id]},
        %{assigns: %{user: user}} = socket
      ) do
    if user._id in [user_1, user_2] do
      stranger = if(user._id == user_1, do: user_2, else: user_1) |> Accounts.get_user()

      Process.send_after(self(), {:redirect_after_match, conversation_id}, 3000)
      {:noreply, assign(socket, status: {:matched, conversation_id}, stranger: stranger)}
    else
      {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:redirect_after_match, conversation_id}, socket) do
    socket =
      push_redirect(socket,
        to:
          Routes.room_path(
            socket,
            :index,
            BSON.ObjectId.encode!(conversation_id)
          )
      )

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def terminate(_reason, %{assigns: %{user: user}} = _socket) do
    UserTracker.remove_user(user._id, :active_users)
  end

  defp dashboard_status(assigns) do
    case assigns.status do
      :searching ->
        ~E"""
          <div class="flex-container">
            <div id="user">
              <%= get_avatar_url(@user) |> img_tag %>
            </div>
            <div id="search">
              <span id="search-text"> Searching... </span>
            </div>
            <div id="stranger"></div>
          </div>
          <div id="search-button">
            <button class="btn btn-primary" phx-click="stop_search">Stop Searching</button>
          </div>
        """

      {:matched, conversation_id} ->
        ~E"""
        <div class="flex-container">
          <span> You have matched with <%= @stranger.profile.first_name %> </span>
          <div id="user">
            <%= get_avatar_url(@user) |> img_tag %>
          </div>
        </div>
        """

      _ ->
        ~E"""
        <button class="btn btn-primary" phx-click="search">Start Searching</button>
        """
    end
  end
end
