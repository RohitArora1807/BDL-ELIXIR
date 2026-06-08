defmodule ElixirAppWeb.FavoriteController do
  use ElixirAppWeb, :controller

  alias ElixirApp.Favorites
  alias ElixirApp.Favorites.Favorite
  alias ElixirApp.Repo

  action_fallback ElixirAppWeb.FallbackController

  def index(conn, %{"user_id" => user_id}) do
    favorites = Favorites.list_favorites(user_id)
    render(conn, :index, favorites: favorites)
  end

  def create(conn, %{"favorite" => params}) do
    with {:ok, %Favorite{} = favorite} <- Favorites.add_favorite(params) do
      favorite = Repo.preload(favorite, :property)

      conn
      |> put_status(:created)
      |> render(:show, favorite: favorite)
    end
  end

  def delete(conn, %{"id" => id}) do
    favorite = Favorites.get_favorite!(id)

    with {:ok, %Favorite{}} <- Favorites.remove_favorite(favorite) do
      send_resp(conn, :no_content, "")
    end
  end
end
