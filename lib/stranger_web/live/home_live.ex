defmodule StrangerWeb.HomeLive do
  use StrangerWeb, :live_view
  use Phoenix.HTML
  import StrangerWeb.ErrorHelpers

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(
       socket,
       %{
         changeset: Stranger.Accounts.User.registration_changeset(%{})
       }
     )}
  end

  @impl true
  def handle_event("validate", %{"user" => params}, socket) do
    changeset =
      params
      |> Stranger.Accounts.User.registration_changeset()
      # Erros are only shown on form submit action, since we use live view the form is not yet submitted so we have to change the action argument
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Stranger.Accounts.create_user(user_params) do
      {:ok, user} ->
        {:noreply, put_flash(socket, :info, "user created")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: Map.put(changeset, :action, :insert))}
    end
  end
end
