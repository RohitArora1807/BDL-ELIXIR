defmodule ElixirAppWeb.PageController do
  use ElixirAppWeb, :controller

  def index(conn, _params) do
    if get_session(conn, :user_id) do
      redirect(conn, to: "/app/dashboard")
    else
      redirect(conn, to: "/login")
    end
  end
end
