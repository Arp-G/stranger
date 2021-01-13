defmodule StrangerWeb.HomeLive do
  use Phoenix.LiveView
  alias Stranger.{Accounts, Accounts.User, Uploaders.Avatar}

  @flash_messages %{
    "create_avatar_error" => "Registered successfully but avatar upload failed",
    "update_avatar_error" => "Profile updated but avattar update failed",
    "create_success" => "User registered successfully",
    "update_success" => "Profile updated successfully",
    "create_error" => "Could not register user check for errors",
    "update_error" => "Could not update profile check for errors"
  }

  @impl true
  def mount(_params, session, socket) do
    [mode, user] =
      case StrangerWeb.Plugs.UserAuth.get_user_id(session["token"]) do
        {:ok, user_id} -> ["update", Accounts.get_user(user_id)]
        _ -> ["create", %User{}]
      end

    {:ok,
     socket
     |> assign(%{
       user: user,
       changeset: User.registration_changeset(%{}, user),
       section: if(mode == "create", do: 0, else: 1),
       uploaded_files: [],
       mode: mode
     })
     |> allow_upload(:avatar, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
  end

  @impl true
  def render(assigns) do
    if assigns.mode == "create" do
      # For having custom template files
      # here we need to defin a view "HomeLiveView" and keep the leex templates properly in the templates deirectory
      Phoenix.View.render(StrangerWeb.HomeLiveView, "home_live.html", assigns)
    else
      Phoenix.View.render(StrangerWeb.HomeLiveView, "settings_live.html", assigns)
    end
  end

  @impl true
  def handle_event("validate", %{"user" => params}, socket) do
    changeset =
      params
      |> User.validation_changeset()
      # Erros are only shown on form submit action, since we use live view the form is not yet submitted so we have to change the action argument
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_event("validate_email", _args, %{assigns: %{changeset: changeset}} = socket) do
    changeset =
      changeset
      |> User.validate_unique_email()
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case create_or_update(user_params, socket) do
      {:ok, user} ->
        case handle_avatar_upload(socket, user) do
          {:error, _} ->
            {
              :noreply,
              socket
              |> put_flash(:error, flash_message("avatar_error", socket))
              |> redirect(to: StrangerWeb.Router.Helpers.home_path(socket, :index))
            }

          _ ->
            {
              :noreply,
              socket
              |> put_flash(:info, flash_message("success", socket))
              |> redirect(to: StrangerWeb.Router.Helpers.home_path(socket, :index))
            }
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {
          :noreply,
          socket
          |> assign(changeset: Map.put(changeset, :action, :insert))
          |> clear_flash()
          |> put_flash(:error, "error")
        }
    end
  end

  @impl true
  def handle_event("next", _args, %{assigns: %{section: section_number}} = socket) do
    section_number = if section_number < 2, do: section_number + 1, else: section_number
    {:noreply, assign(socket, section: section_number)}
  end

  @impl true
  def handle_event("prev", _args, %{assigns: %{section: section_number}} = socket) do
    section_number = if section_number > 0, do: section_number - 1, else: section_number
    {:noreply, assign(socket, section: section_number)}
  end

  @impl true
  def handle_event("jump_to_" <> jump_to, _args, socket) do
    {:noreply, assign(socket, section: String.to_integer(jump_to))}
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

  defp create_or_update(user_params, socket) do
    if socket.assigns.mode == "create" do
      Accounts.create_user(user_params)
    else
      Accounts.update_user(socket.assigns.user._id, socket.assigns.changeset, user_params)
    end
  end

  defp flash_message(error, socket) do
    error = "#{socket.assigns.mode}_#{error}"

    Map.get(@flash_messages, error)
  end
end

# p = "live_view_upload-1609522426-906582229084086-5"
# Avatar.url({user.profile.avatar, user}, signed: true)
