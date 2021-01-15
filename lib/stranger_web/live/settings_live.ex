defmodule StrangerWeb.SettingsLive do
  use StrangerWeb, :live_view
  import StrangerWeb.LiveHelpers
  alias Stranger.{Accounts, Accounts.User, Accounts.Profile}

  @impl Phoenix.LiveView
  def mount(
        _params,
        %{"token" => token} = _session,
        socket
      ) do
    {:ok, user_id} = StrangerWeb.Plugs.UserAuth.get_user_id(token)

    user = Accounts.get_user(user_id)

    {:ok,
     assign(socket,
       user: user,
       password_changeset: User.password_changeset(user),
       profile_changeset: Profile.changeset(user.profile, %{})
     )}
  end

  @impl true
  def handle_event("validate_password", %{"user" => params}, socket) do
    password_changeset =
      %User{}
      |> User.password_changeset(params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, password_changeset: password_changeset)}
  end

  @impl true
  def handle_event(
        "update_password",
        %{"user" => %{"current_password" => current_password}},
        socket
      ) do
    if Accounts.verify_password(current_password, socket.assigns.user) == :error do
      {
        :noreply,
        socket
        |> clear_flash()
        |> put_flash(:error, "Current password is incorrect")
      }
    else
      case Accounts.update_password(socket.assigns.user._id, socket.assigns.password_changeset) do
        {:error, password_changeset} ->
          {
            :noreply,
            socket
            |> assign(changeset: Map.put(password_changeset, :action, :insert))
            |> clear_flash()
            |> put_flash(:error, "Could not update password")
          }

        _ ->
          {
            :noreply,
            socket
            |> clear_flash()
            |> put_flash(:info, "Password updated successfully")
          }
      end
    end
  end

  @impl Phoenix.LiveView
  def handle_event("validate_profile", %{"profile" => params}, socket) do
    profile_changeset =
      Profile.changeset(socket.assigns.user.profile, params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, profile_changeset: profile_changeset)}
  end

  @impl Phoenix.LiveView
  def handle_event("update_profile", %{"profile" => params}, socket) do
    socket.assigns.user
    |> Accounts.update_profile(params)
    |> case do
      {:error, profile_changeset} ->
        {
          :noreply,
          socket
          |> assign(profile_changeset: profile_changeset |> Map.put(:action, :insert))
          |> clear_flash()
          |> put_flash(:error, "Failed to update profile, check for errors")
        #  |> redirect(to: StrangerWeb.Router.Helpers.settings_path(socket, :index))
        }

      _ ->
        {
          :noreply,
          socket
          |> clear_flash()
          |> put_flash(:info, "Profile updated successfully")
        #  |> redirect(to: StrangerWeb.Router.Helpers.settings_path(socket, :index))
        }
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~L"""
    <h2> Update Profile </h2>
    <div>
      <%= f = form_for @profile_changeset, "#", [phx_change: :validate_profile, phx_submit: :update_profile] %>

        <p>
          <%= label f, :first_name %>
          <%= text_input f, :first_name %>
          <p><%= error_tag f, :first_name %></p>
        </p>

        <p>
          <%= label f, :last_name %>
          <%= text_input f, :last_name %>
          <p><%= error_tag f, :last_name %></p>
        </p>

        <p>
          <%= label f, :dob %>
          <%= date_input f, :dob, value: format_date(f) %>
          <p><%= error_tag f, :dob %></p>
        </p>

        <p>
          <%= label f, :country %>
          <%= text_input f, :country %>
          <p><%= error_tag f, :country %></p>
        </p>

        <p>
          <%= label f, :bio %>
          <%= textarea f, :bio %>
          <p><%= error_tag f, :bio %></p>
        </p>

        <p>
          <%= submit "Update Profile", "phx-disable-with": "Saving...", class: "btn btn-primary" %>
        </p>
      </form>

      <hr>
      <h2> Update Password </h2>

      <%= f = form_for @password_changeset, "#", [phx_change: :validate_password, phx_submit: :update_password] %>
        <p>

          <p>
            <%= label f, :current_password %>
            <%= password_input f, :current_password, value: input_value(f, :current_password) %>
          </p>

          <%= label f, :password %>
          <%= password_input f, :password, value: input_value(f, :password) %>
          <br><br>
          <p><%= error_tag f, :password %></p>

          <%= label f, :password_confirmation %>
          <%= password_input f, :password_confirmation, value: input_value(f, :password_confirmation) %>
          <p><%= error_tag f, :password_confirmation %></p>

        </p>
        <p>
          <%= submit "Update password", "phx-disable-with": "Saving...", class: "btn btn-primary" %>
        </p>
      </form>
    </div>
    """
  end
end
