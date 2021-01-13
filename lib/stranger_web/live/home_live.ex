defmodule StrangerWeb.HomeLive do
  use StrangerWeb, :live_view
  use Phoenix.HTML
  alias Stranger.{Accounts, Accounts.User, Uploaders.Avatar}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(%{
       changeset: User.registration_changeset(%{}),
       section: 0,
       uploaded_files: []
     })
     |> allow_upload(:avatar, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
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
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        case handle_avatar_upload(socket, user) do
          {:error, _} ->
            {
              :noreply,
              socket
              |> put_flash(:error, "Registered successfully but avatar upload failed")
              |> redirect(to: StrangerWeb.Router.Helpers.home_path(socket, :index))
            }

          _ ->
            {
              :noreply,
              socket
              |> put_flash(:info, "User registered successfully")
              |> redirect(to: StrangerWeb.Router.Helpers.home_path(socket, :index))
            }
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {
          :noreply,
          socket
          |> assign(changeset: Map.put(changeset, :action, :insert))
          |> clear_flash()
          |> put_flash(:error, "Could not register user check for errors")
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
end

# p = "live_view_upload-1609522426-906582229084086-5"
# Avatar.url({user.profile.avatar, user}, signed: true)
