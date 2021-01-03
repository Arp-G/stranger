defmodule StrangerWeb.UserAuthPlug do
  @moduledoc """
  This module containes a plug for user authentication.
  """

  import Plug.Conn
  import Phoenix.Controller
  alias StrangerWeb.Router.Helpers, as: Routes
  alias Stranger.{Accounts, Accounts.User}

  def init(options) do
    options
  end

  def call(conn, _opts) do
    case Phoenix.Token.verify(
           Application.get_env(:stranger, :secret_key),
           Application.get_env(:stranger, :salt),
           get_session(conn, :token),
           max_age: 86400
         ) do
      {:ok, user_id} ->
        assign(conn, :user, Accounts.get_user(user_id))

      {:error, _} ->
        conn
        |> put_flash(:error, "You must be logged in to access that page")
        |> redirect(to: Routes.home_path(conn, :index))
        |> halt()
    end
  end

  # @spec logout_user(Plug.Conn.t()) :: Plug.Conn.t()
  # def logout_user(conn) do
  #   conn
  #   |> renew_session()
  #   |> put_flash(:info, "Logged out successfully.")
  #   |> redirect(to: Routes.page_path(conn, :index))
  # end

  # @spec verify_correct_user(Plug.Conn.t(), any) :: Plug.Conn.t()
  # def verify_correct_user(conn, _opts) do

  #   conn
  #   |> put_flash(:error, "Unautherized")
  #   |> redirect(to: Routes.page_path(conn, :index))
  #   |> halt()
  # end
end
