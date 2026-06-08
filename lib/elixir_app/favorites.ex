defmodule ElixirApp.Favorites do
  import Ecto.Query, warn: false
  alias ElixirApp.Repo
  alias ElixirApp.Favorites.Favorite

  def list_favorites(user_id) do
    Favorite
    |> where([f], f.user_id == ^user_id)
    |> preload(:property)
    |> Repo.all()
  end

  def get_favorite!(id), do: Repo.get!(Favorite, id)

  def add_favorite(attrs) do
    %Favorite{}
    |> Favorite.changeset(attrs)
    |> Repo.insert()
  end

  def remove_favorite(%Favorite{} = favorite), do: Repo.delete(favorite)

  def favorited?(user_id, property_id) do
    Repo.exists?(from f in Favorite, where: f.user_id == ^user_id and f.property_id == ^property_id)
  end
end
