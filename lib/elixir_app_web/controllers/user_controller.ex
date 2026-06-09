defmodule ElixirAppWeb.UserController do
  use ElixirAppWeb, :controller

  alias ElixirApp.Accounts

  action_fallback ElixirAppWeb.FallbackController

  def register(conn, %{"user" => params}) do
    with {:ok, user} <- Accounts.register_user(params) do
      token = Accounts.generate_token(user)

      conn
      |> put_status(:created)
      |> render(:auth, user: user, token: token)
    end
  end

  def login(conn, %{"email" => email, "password" => password}) do
    with {:ok, user} <- Accounts.authenticate_user(email, password) do
      token = Accounts.generate_token(user)
      render(conn, :auth, user: user, token: token)
    end
  end

  def me(conn, _params) do
    render(conn, :show, user: conn.assigns.current_user)
  end
end
