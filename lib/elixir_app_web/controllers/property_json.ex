defmodule ElixirAppWeb.PropertyJSON do
  alias ElixirApp.Properties.Property
  alias ElixirApp.Accounts.User

  def index(%{properties: properties}), do: %{data: Enum.map(properties, &data/1)}

  def show(%{property: property}), do: %{data: data(property)}

  defp data(%Property{} = p) do
    %{
      id:          p.id,
      title:       p.title,
      description: p.description,
      price:       p.price,
      location:    p.location,
      bedrooms:    p.bedrooms,
      bathrooms:   p.bathrooms,
      area:        p.area,
      type:        p.type,
      status:      p.status,
      owner_id:    p.owner_id,
      owner:       owner_data(p.owner)
    }
  end

  defp owner_data(%User{} = u), do: %{id: u.id, name: u.name, email: u.email}
  defp owner_data(_), do: nil
end
