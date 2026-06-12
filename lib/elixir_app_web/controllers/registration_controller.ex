defmodule ElixirAppWeb.RegistrationController do
  use ElixirAppWeb, :controller

  alias ElixirApp.Accounts

  def create(conn, params) do
    attrs = %{
      name:     params["name"],
      email:    params["email"],
      password: params["password"],
      role:     params["role"] || "buyer"
    }

    case Accounts.register_user(attrs) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> redirect(to: "/app/dashboard")

      {:error, changeset} ->
        msg = changeset.errors
              |> Enum.map(fn {k, {v, _}} -> "#{k} #{v}" end)
              |> Enum.join(", ")

        conn
        |> put_flash(:error, msg)
        |> redirect(to: "/register")
    end
  end
end
