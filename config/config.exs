# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :stranger, StrangerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "yCI36NRhRxnLEy8oaiTJUYzRHjX/rhptbtEnkU6MId+XLlPa09nesBJxM7288FvG",
  render_errors: [view: StrangerWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Stranger.PubSub,
  live_view: [signing_salt: "DxT8QMf8"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ex_opentok,
  iss: "project",
  key: "47058914",
  secret: "746dbb06abca59262d6d1e4db51c06361d641d3b",
  ttl: 300

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
