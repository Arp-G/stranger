defmodule StrangerWeb.SettingsLive do
  use StrangerWeb, :live_view
  alias Stranger.{Accounts, Accounts.User}

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
       password_changeset: User.password_changeset(user)
     )}
  end

  @impl true
  def handle_event("validate_password", %{"user" => params}, socket) do
    password_changeset =
      %User{}
      |> User.password_changeset(params)
      |> Map.put(:action, :insert)

    IO.inspect(password_changeset)

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
  def render(assigns) do
    ~L"""
    <h2> Change Password </h2>
    <div>
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
