defmodule StrangerWeb.UserProfileComponent do
  use StrangerWeb, :live_component
  alias Stranger.Uploaders.Avatar


  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~L"""
      <div class="card w-50 mx-auto mt-5 pt-2">
        <%= get_avatar_url(@user) %>
        <div class="card-body mx-auto text-center">
          <h2><%= "#{@user.profile.first_name} #{@user.profile.last_name}" %></h2>

          <%= if @user.profile.country do %>
            <p>
              <i class="fa fa-map-marker" aria-hidden="true"></i>
              <%= @user.profile.country %>
            </p>
          <% end %>

          <%= if @user.profile.dob do %>
            <p>
              <i class="fa fa-birthday-cake" aria-hidden="true"></i>
              <%= calculate_age(@user.profile.dob) %>
            </p>
          <% end %>
          <hr>
          <%= if @user.profile.bio do %>
            <p> <%= @user.profile.bio %> </p>
          <% end %>

        </div>
      </div>
    """
  end
end
