defmodule StrangerWeb.HomeLive do
  use StrangerWeb, :live_view
  use Phoenix.HTML
  alias Stranger.{Accounts, Accounts.User}

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(%{
       changeset: User.registration_changeset(%{}),
       section: 0
     })
     |> allow_upload(:avatar, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"user" => params}, socket) do
    changeset =
      params
      |> User.validation_changeset()
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate_email", _args, %{assigns: %{changeset: changeset}} = socket) do
    changeset =
      changeset
      |> User.validate_unique_email()
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        case handle_avatar_upload(socket, user) do
          {:error, _} ->
            {
              :noreply,
              socket
              |> put_flash(:error, "Registered successfully but avatar upload failed")
              |> redirect(
                to:
                  StrangerWeb.Router.Helpers.session_path(socket, :sign_in, %{
                    email: user_params["email"],
                    password: user_params["password"]
                  })
              )
            }

          _ ->
            {
              :noreply,
              socket
              |> put_flash(:info, "User registered successfully")
              |> redirect(
                to:
                  StrangerWeb.Router.Helpers.session_path(socket, :sign_in, %{
                    email: user_params["email"],
                    password: user_params["password"]
                  })
              )
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

  @impl Phoenix.LiveView
  # Cancel all subsequest uploads
  def handle_event("on_upload", _, %{assigns: %{uploads: uploads}} = socket) do
    case uploads.avatar.entries do
      [first, _last] ->
        {:noreply, cancel_upload(socket, :avatar, first.ref)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  @impl Phoenix.LiveView
  def handle_event("next", _args, %{assigns: %{section: section_number}} = socket) do
    section_number = if section_number < 3, do: section_number + 1, else: section_number
    {:noreply, assign(socket, section: section_number)}
  end

  @impl Phoenix.LiveView
  def handle_event("prev", _args, %{assigns: %{section: section_number}} = socket) do
    section_number = if section_number > 0, do: section_number - 1, else: section_number
    {:noreply, assign(socket, section: section_number)}
  end

  @impl Phoenix.LiveView
  def handle_event("jump_to_" <> jump_to, _args, socket) do
    {:noreply, assign(socket, section: String.to_integer(jump_to))}
  end
end
