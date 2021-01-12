defmodule StrangerWeb.CorrectConversation do
  @moduledoc """
  This module containes a plug to check if the user is a participant in the conversation
  """

  import Plug.Conn
  import Phoenix.Controller
  alias StrangerWeb.Router.Helpers, as: Routes
  alias Stranger.Conversations

  def init(options) do
    options
  end

  def call(
        %{assigns: %{user: user}, path_params: %{"conversation_id" => conversation_id}} = conn,
        _opts
      ) do
    if Conversations.check_if_user_belongs_to_conversation(
         user._id,
         BSON.ObjectId.decode!(conversation_id)
       ) do
      conn
    else
      conn
      |> put_flash(:error, "You are not allowed visit this page")
      |> redirect(to: Routes.dashboard_path(conn, :index))
      |> halt()
    end
  end
end
