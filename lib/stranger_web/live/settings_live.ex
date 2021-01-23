defmodule StrangerWeb.SettingsLive do
  use StrangerWeb, :live_view
  alias Stranger.{Accounts, Accounts.User, Accounts.Profile, Uploaders.Avatar}

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    socket = assign_defaults(socket, session)

    {:ok,
     socket
     |> assign(
       password_changeset: User.password_changeset(socket.assigns.user),
       remove_existing_avatar: false,
       profile_changeset: Profile.changeset(socket.assigns.user.profile, %{})
     )
     |> allow_upload(:avatar, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate_password", %{"user" => params}, socket) do
    password_changeset =
      %User{}
      |> User.password_changeset(params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, password_changeset: password_changeset)}
  end

  @impl Phoenix.LiveView
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
      socket.assigns.user.profile
      |> Profile.changeset(params)
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
  @impl Phoenix.LiveView
  def handle_event("on_upload", _, %{assigns: %{uploads: uploads}} = socket) do
    {:noreply,
     case uploads.avatar.entries do
       [first, _last] ->
         cancel_upload(socket, :avatar, first.ref)

       _ ->
         socket
     end
     |> assign(remove_existing_avatar: true)}
  end

  @impl Phoenix.LiveView
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  @impl Phoenix.LiveView
  def handle_event("remove-existing-avatar", %{}, socket) do
    {:noreply, assign(socket, remove_existing_avatar: true)}
  end

  defp img_preview(assigns) do
    cond do
      !assigns.remove_existing_avatar && is_nil(List.last(assigns.uploads.avatar.entries)) ->
        ~L"""
          <%= img_tag(get_avatar_url(assigns.user), class: "avatar_img") %>
          <%= if assigns.user.profile.avatar do %>
            <a href="#" phx-click="remove-existing-avatar">&times</a>
          <% end %>
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
    <div class="settings_form">
    <div class="form_heading settings_page_heading"> Update Profile </div>
      <%= f = form_for @profile_changeset, "#", [phx_change: :validate_profile, phx_submit: :update_profile] %>
        <div class="form-group">
          <%= img_preview(assigns) %>
        </div>

        <div class="form-group">
          <%= live_file_input @uploads.avatar, phx_blur: :on_upload %>
          <p><%= error_tag f, :avatar %></p>
          <br>
          <%= if entry = List.last(@uploads.avatar.entries) do %>
            Uploaded - <strong><%= entry.progress %>%</strong>
          <% end %>
        </div>

        <div class="form-group">
          <span class="required_field"> * </span>
          <%= label f, :first_name %>
          <%= text_input f, :first_name, class: "form-control" %>
          <p><%= error_tag f, :first_name %></p>
        </div>

        <div class="form-group">
          <span class="required_field"> * </span>
          <%= label f, :last_name %>
          <%= text_input f, :last_name, class: "form-control" %>
          <p><%= error_tag f, :last_name %></p>
        </div>

        <div class="form-group">
          <%= label f, :dob %>
          <%= date_input f, :dob, value: format_date(f), class: "form-control" %>
          <p><%= error_tag f, :dob %></p>
        </div>

        <div class="form-group">
          <%= label f, :country %>
          <%= text_input f, :country, class: "form-control" %>
          <p><%= error_tag f, :country %></p>
        </div>

        <div class="form-group">
          <%= label f, :bio %>
          <%= textarea f, :bio, class: "form-control", placeholder: "Write something about yourself. You can mention your hobbies, passion, etc", rows: 5 %>
          <p><%= error_tag f, :bio %></p>
        </div>

        <div class="form-group">
          <%= submit "Update Profile", "phx-disable-with": "Saving...", class: "btn btn-success" %>
        </div>
      </form>
    </div>

      <hr>

    <div class="settings_form">
     <div class="form_heading settings_page_heading"> Change Password </div>

      <%= f = form_for @password_changeset, "#", [phx_change: :validate_password, phx_submit: :update_password] %>
        <p>
          <div class="form-group">
            <%= label f, :current_password %>
            <%= password_input f, :current_password, value: input_value(f, :current_password), class: "form-control" %>
          </div>

          <div class="form-group">
            <%= label f, "New password" %>
            <%= password_input f, :password, value: input_value(f, :password), class: "form-control" %>
            <p><%= error_tag f, :password %></p>
          </div>

          <div class="form-group">
            <%= label f, :password_confirmation %>
            <%= password_input f, :password_confirmation, value: input_value(f, :password_confirmation), class: "form-control" %>
            <p><%= error_tag f, :password_confirmation %></p>
          </div>
        </p>
        <div class="form-group">
          <%= submit "Update password", "phx-disable-with": "Saving...", class: "btn btn-warning" %>
        </div>
      </form>
    </div>
    """
  end
end
