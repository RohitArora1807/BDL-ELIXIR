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

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:forbidden)
    |> put_view(html: ElixirAppWeb.ErrorHTML, json: ElixirAppWeb.ErrorJSON)
    |> render(:"403")
  end

  def call(conn, {:error, :invalid_credentials}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(html: ElixirAppWeb.ErrorHTML, json: ElixirAppWeb.ErrorJSON)
    |> render(:"401")
  end
end
