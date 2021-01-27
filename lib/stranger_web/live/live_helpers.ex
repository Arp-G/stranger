defmodule StrangerWeb.LiveHelpers do
  alias Stranger.{Accounts, Uploaders.Avatar}
  import Phoenix.LiveView
  use Phoenix.HTML
  @env Mix.env()

  def section_class(current_section, section) do
    if section != current_section, do: "d-none", else: ""
  end

  def format_date(form_data) do
    cond do
      # Comes from form_data params when user changes date in form
      form_data.params["dob"] ->
        form_data.params["dob"]
        |> DateTime.from_iso8601()
        |> case do
          {:ok, datetime, 0} -> DateTime.to_date(datetime)
          {:error, _} -> form_data.params["dob"]
        end

      # Comes from form_data data to prefill existing dob in form if present, usefull in update form
      form_data.data.dob ->
        form_data.data.dob
        |> DateTime.to_date()
        |> Date.to_iso8601()

      true ->
        nil
    end
  end

  def handle_avatar_upload(socket, user) do
    consume_uploaded_entries(socket, :avatar, fn %{path: path}, _entry ->
      dest_directory = "#{:code.priv_dir(:stranger)}/uploads"
      File.mkdir_p(dest_directory)
      dest = Path.join(dest_directory, Path.basename(path))
      File.cp!(path, dest)
      dest
    end)
    |> case do
      [file_path] ->
        case Avatar.store({file_path, user}) do
          {:ok, img_url} ->
            File.rm!(file_path)
            Accounts.update_avatar(user, img_url)

          _ ->
            File.rm(file_path)
            {:error, "Image upload failed"}
        end

      _ ->
        :ok
    end
  end

  def get_avatar_url(user) do
    if user.profile.avatar do
      Avatar.url({user.profile.avatar, user}, signed: true)
    else
      StrangerWeb.Router.Helpers.static_path(
        StrangerWeb.Endpoint,
        "/images/avatar_placeholder.png"
      )
    end
  end

  def get_avatar_img(user) do
    if user.profile.avatar do
      img_tag(Avatar.url({user.profile.avatar, user}, signed: true), class: "avatar_img mx-auto")
    else
      ~E"""
        <i class="fa fa-user avatar-placeholder" aria-hidden="true"></i>
      """
    end
  end

  def calculate_age(dob) do
    Timex.diff(DateTime.utc_now(), dob, :duration)
    |> Elixir.Timex.Format.Duration.Formatters.Humanized.format()
    |> String.split(",")
    |> Enum.take(2)
    |> Enum.join(",")
  end

  def assign_defaults(socket, %{"token" => token} = _session) do
    case StrangerWeb.Plugs.UserAuth.get_user_id(token) do
      {:ok, user_id} ->
        # Assign tosocket only if the assigns is not present already, avoids unecessary user query
        # reusing any of the connection assigns from the HTTP request
        socket = assign_new(socket, :user, fn -> Stranger.Accounts.get_user(user_id) end)

        if socket.assigns.user, do: socket, else: redirect_to_login(socket)

      _ ->
        redirect_to_login(socket)
    end
  end

  def get_sender_name(message, user, stranger) do
    sender = if message.sender_id == user._id, do: user, else: stranger

    sender.profile.first_name
  end

  def get_msg_bubble_class(message, user) do
    if message.sender_id == user._id,
      do: "bubble bubble-bottom-left",
      else: "bubble bubble-bottom-right"
  end

  defp redirect_to_login(socket) do
    socket
    |> put_flash(:error, "You must be logged in to access that page")
    |> redirect(to: StrangerWeb.Router.Helpers.home_path(socket, :index))
  end
end
