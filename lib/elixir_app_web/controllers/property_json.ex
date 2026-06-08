defmodule ElixirAppWeb.PropertyJSON do
  alias ElixirApp.Properties.Property

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
      status:      p.status
    }
  end
end
