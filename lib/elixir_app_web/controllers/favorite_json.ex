defmodule ElixirAppWeb.FavoriteJSON do
  alias ElixirApp.Favorites.Favorite

  def index(%{favorites: favorites}), do: %{data: Enum.map(favorites, &data/1)}

  def show(%{favorite: favorite}), do: %{data: data(favorite)}

  defp data(%Favorite{} = f) do
    %{
      id:          f.id,
      user_id:     f.user_id,
      property_id: f.property_id,
      property:    property_data(f.property)
    }
  end

  defp property_data(%{id: id, title: title, price: price, location: location, status: status}) do
    %{id: id, title: title, price: price, location: location, status: status}
  end
  defp property_data(_), do: nil
end
