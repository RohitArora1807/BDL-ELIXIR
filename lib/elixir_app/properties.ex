defmodule ElixirApp.Properties do
  import Ecto.Query, warn: false
  alias ElixirApp.Repo
  alias ElixirApp.Properties.Property

  def list_properties, do: Repo.all(Property)

  def get_property!(id), do: Repo.get!(Property, id)

  def create_property(attrs) do
    %Property{}
    |> Property.changeset(attrs)
    |> Repo.insert()
  end

  def update_property(%Property{} = property, attrs) do
    property
    |> Property.changeset(attrs)
    |> Repo.update()
  end

  def delete_property(%Property{} = property), do: Repo.delete(property)
end
