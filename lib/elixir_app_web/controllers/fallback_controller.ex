defmodule ElixirAppWeb.FallbackController do
  use ElixirAppWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: ElixirAppWeb.ChangesetJSON)
    |> render(:error, changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(html: ElixirAppWeb.ErrorHTML, json: ElixirAppWeb.ErrorJSON)
    |> render(:"404")
  end
end
