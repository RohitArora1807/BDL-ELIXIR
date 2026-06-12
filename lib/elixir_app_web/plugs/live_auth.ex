defmodule ElixirAppWeb.Plugs.LiveAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias ElixirApp.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)
    user    = user_id && Accounts.get_user(user_id)

    if user do
      assign(conn, :current_user, user)
    else
      conn
      |> put_flash(:error, "Please sign in to continue.")
      |> redirect(to: "/login")
      |> halt()
    end
  end
end
