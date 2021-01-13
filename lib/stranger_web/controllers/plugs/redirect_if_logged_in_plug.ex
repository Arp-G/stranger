defmodule StrangerWeb.Plugs.RedirectIfLoggedInPlug do
  @moduledoc """
  This module containes a plug to check if the user is a participant in the conversation
  """

  import Plug.Conn
  import Phoenix.Controller
  alias StrangerWeb.Router.Helpers, as: Routes

  def init(options) do
    options
  end

  def call(conn, _opts) do
    conn
    |> get_session(:token)
    |> StrangerWeb.Plugs.UserAuth.get_user_id()
    |> case do
      {:ok, _user_id} ->
        conn
        |> redirect(to: Routes.dashboard_path(conn, :index))
        |> halt()

      {:error, _} ->
        conn
    end
  end
end
