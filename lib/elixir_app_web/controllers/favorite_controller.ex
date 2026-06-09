defmodule ElixirAppWeb.FavoriteController do
  use ElixirAppWeb, :controller

  alias ElixirApp.Favorites
  alias ElixirApp.Favorites.Favorite
  alias ElixirApp.Repo

  action_fallback ElixirAppWeb.FallbackController

  def index(conn, _params) do
    favorites = Favorites.list_favorites(conn.assigns.current_user.id)
    render(conn, :index, favorites: favorites)
  end

  def create(conn, %{"favorite" => params}) do
    params = Map.put(params, "user_id", conn.assigns.current_user.id)

    with {:ok, %Favorite{} = favorite} <- Favorites.add_favorite(params) do
      favorite = Repo.preload(favorite, :property)

      conn
      |> put_status(:created)
      |> render(:show, favorite: favorite)
    end
  end

  def delete(conn, %{"id" => id}) do
    favorite = Favorites.get_favorite!(id)

    with :ok <- (if favorite.user_id == conn.assigns.current_user.id, do: :ok, else: {:error, :unauthorized}),
         {:ok, %Favorite{}} <- Favorites.remove_favorite(favorite) do
      send_resp(conn, :no_content, "")
    end
  end
end
