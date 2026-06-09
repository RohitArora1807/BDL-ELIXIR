defmodule ElixirAppWeb.AdminController do
  use ElixirAppWeb, :controller

  alias ElixirApp.Accounts

  action_fallback ElixirAppWeb.FallbackController

  def index(conn, _params) do
    with :ok <- require_admin(conn) do
      users = Accounts.list_users()
      render(conn, :index, users: users)
    end
  end

  def update(conn, %{"id" => id, "user" => params}) do
    with :ok <- require_admin(conn) do
      user = Accounts.get_user!(id)

      with {:ok, user} <- Accounts.update_user_role(user, params) do
        render(conn, :show, user: user)
      end
    end
  end

  defp require_admin(%{assigns: %{current_user: %{role: "admin"}}}), do: :ok
  defp require_admin(_), do: {:error, :unauthorized}
end
