defmodule StrangerWeb.SessionController do
  use StrangerWeb, :controller

  def sign_in(conn, %{"email" => email, "password" => password}) do
    case Stranger.Accounts.sign_in(current_ip(conn), email, password) do
      {:ok, token} ->
        conn
        |> put_session(:token, token)
        |> configure_session(renew: true)
        |> redirect(to: "/dashboard")

      _ ->
        conn
        |> put_flash(:error, "Incorrect login credentials")
        |> redirect(to: "/")
    end
  end

  defp current_ip(conn) do
    conn.remote_ip
    |> :inet_parse.ntoa()
    |> to_string()
  end
end
