defmodule ElixirApp.Repo do
  use AshPostgres.Repo,
    otp_app: :elixir_app

  def min_pg_version, do: %Version{major: 14, minor: 0, patch: 0}

  def installed_extensions do
    ["uuid-ossp", "citext", "ash-functions"]
  end
end
