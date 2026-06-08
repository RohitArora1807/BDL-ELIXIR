defmodule ElixirApp.Favorites.Favorite do
  use Ecto.Schema
  import Ecto.Changeset

  schema "favorites" do
    field :user_id, :integer
    belongs_to :property, ElixirApp.Properties.Property

    timestamps(type: :utc_datetime)
  end

  def changeset(favorite, attrs) do
    favorite
    |> cast(attrs, [:user_id, :property_id])
    |> validate_required([:user_id, :property_id])
    |> unique_constraint([:user_id, :property_id])
  end
end
