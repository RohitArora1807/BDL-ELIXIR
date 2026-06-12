# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :elixir_app,
  ecto_repos: [ElixirApp.Repo],
  generators: [timestamp_type: :utc_datetime]

config :ash, :domains, [ElixirApp.RealEstate]
config :elixir_app, ash_domains: [ElixirApp.RealEstate]

# Configure the endpoint
config :elixir_app, ElixirAppWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: ElixirAppWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ElixirApp.PubSub,
  live_view: [signing_salt: "yitnlKOn"]

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :elixir_app, ElixirApp.Mailer, adapter: Swoosh.Adapters.Local

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Oban background job processing
# queues: default handles email/SMS workers
# 10 concurrent jobs max on the default queue
config :elixir_app, Oban,
  engine: Oban.Engines.Basic,
  repo: ElixirApp.Repo,
  queues: [default: 10, mailers: 5]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
