defmodule StrangerWeb.Router do
  use StrangerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {StrangerWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :auth do
    plug StrangerWeb.Plugs.UserAuth
  end

  pipeline :conversations do
    plug StrangerWeb.Plugs.CorrectConversation
  end

  pipeline :redirect_if_logged_in do
    plug StrangerWeb.Plugs.RedirectIfLoggedInPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", StrangerWeb do
    pipe_through :browser

    get "/sign_in", SessionController, :sign_in
  end

  scope "/", StrangerWeb do
    pipe_through :browser
    pipe_through :redirect_if_logged_in

    live "/", HomeLive, :index
  end

  scope "/", StrangerWeb do
    pipe_through :browser
    pipe_through :auth

    live "/dashboard", DashboardLive, :index
    live "/conversations", ConversationsLive, :index
    live "/settings", HomeLive, :index
  end

  scope "/", StrangerWeb do
    pipe_through :browser
    pipe_through :auth
    pipe_through :conversations

    live "/room/:conversation_id", RoomLive, :index
    live "/messages/:conversation_id", MessagesLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", StrangerWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  # if Mix.env() in [:dev, :test] do
  #   import Phoenix.LiveDashboard.Router

  #   scope "/" do
  #     pipe_through :browser
  #     live_dashboard "/dashboard", metrics: StrangerWeb.Telemetry
  #   end
  # end
end
