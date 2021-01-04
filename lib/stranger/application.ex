defmodule Stranger.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      StrangerWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Stranger.PubSub, adapter: Phoenix.PubSub.PG2},
      # Start the Endpoint (http/https)
      StrangerWeb.Endpoint,
      {Mongo, mongo_db()},
      Stranger.UserTracker
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Stranger.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    StrangerWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp mongo_db, do: Application.get_env(:stranger, Mongo)
end
