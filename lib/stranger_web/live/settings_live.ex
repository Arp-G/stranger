defmodule StrangerWeb.SettingsLive do
  use StrangerWeb, :live_view
  import StrangerWeb.LiveHelpers
  alias Stranger.{Accounts, Accounts.User, Accounts.Profile, Uploaders.Avatar}

  @impl Phoenix.LiveView
  def mount(
        _params,
        %{"token" => token} = _session,
        socket
      ) do
    {:ok, user_id} = StrangerWeb.Plugs.UserAuth.get_user_id(token)

    user = Accounts.get_user(user_id)

    {:ok,
     socket
     |> assign(
       user: user,
       password_changeset: User.password_changeset(user),
       remove_existing_avatar: false,
       profile_changeset: Profile.changeset(user.profile, %{})
     )
     |> allow_upload(:avatar, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
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
    params =
      if socket.assigns.remove_existing_avatar, do: Map.put(params, "avatar", nil), else: params

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
        }

      _ ->
        case handle_avatar_upload(socket, socket.assigns.user) do
          {:error, _} ->
            {
              :noreply,
              socket
              |> put_flash(:error, "Avatar upload failed")
            }

          _ ->
            {
              :noreply,
              socket
              |> put_flash(:info, "Profile updated successfully")
              |> redirect(to: Routes.settings_path(socket, :index))
            }
        end
    end
  end

  # Cancel all subsequest uploads
  @impl true
  def handle_event("on_upload", %{}, %{assigns: %{uploads: uploads}} = socket) do
    case uploads.avatar.entries do
      [first, _last] ->
        {:noreply, cancel_upload(socket, :avatar, first.ref)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  def handle_event("remove-existing-avatar", %{}, socket) do
    {:noreply, assign(socket, remove_existing_avatar: true)}
  end

  defp handle_avatar_upload(socket, user) do
    consume_uploaded_entries(socket, :avatar, fn %{path: path}, _entry ->
      dest = Path.join("priv/static/uploads", Path.basename(path))
      File.cp!(path, dest)
      dest
    end)
    |> case do
      [file_path] ->
        case Avatar.store({file_path, user}) do
          {:ok, img_url} ->
            Accounts.update_avatar(user, img_url)

          _ ->
            {:error, "Image upload failed"}
        end

      _ ->
        :ok
    end
  end

  defp img_preview(assigns) do
    cond do
      (avatar = assigns.user.profile.avatar) && !assigns.remove_existing_avatar &&
          is_nil(List.last(assigns.uploads.avatar.entries)) ->
        ~L"""
          <%= img_tag(Avatar.url({assigns.user.profile.avatar, assigns.user}, signed: true), class: "img-thumbnail") %>
          <a href="#" phx-click="remove-existing-avatar">&times</a>
        """

      entry = List.last(assigns.uploads.avatar.entries) ->
        ~L"""
          <%= live_img_preview entry, width: 75 %>
          <a href="#" phx-click="cancel-upload" phx-value-ref="<%= entry.ref %>">&times</a>
        """

      true ->
        nil
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~L"""
    <h2> Update Profile </h2>
    <div>
      <%= f = form_for @profile_changeset, "#", [phx_change: :validate_profile, phx_submit: :update_profile] %>
        <p>
          <%= img_preview(assigns) %>
        </p>
        <p>
          <%= live_file_input @uploads.avatar, phx_blur: :on_upload %>
          <p><%= error_tag f, :avatar %></p>
          <br>
          <%= if entry = List.last(@uploads.avatar.entries) do %>
            Uploaded - <strong><%= entry.progress %>%</strong>
          <% end %>
        </p>



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
