defmodule ElixirApp.Properties do
  import Ecto.Query, warn: false
  alias ElixirApp.Repo
  alias ElixirApp.Properties.Property

  def list_properties do
    Property
    |> preload(:owner)
    |> Repo.all()
  end

  def list_properties_filtered(search \\ "", status \\ "all") do
    Property
    |> filter_search(search)
    |> filter_status_query(status)
    |> preload(:owner)
    |> Repo.all()
  end

  defp filter_search(query, ""), do: query
  defp filter_search(query, search) do
    term = "%#{String.downcase(search)}%"
    where(query, [p], ilike(p.title, ^term) or ilike(p.location, ^term))
  end

  defp filter_status_query(query, "all"), do: query
  defp filter_status_query(query, status), do: where(query, [p], p.status == ^status)

  def list_recent_properties(limit \\ 5) do
    from(p in Property, order_by: [desc: p.inserted_at], limit: ^limit)
    |> preload(:owner)
    |> Repo.all()
  end

  def stats do
    %{
      total:     Repo.aggregate(Property, :count, :id),
      available: Repo.aggregate(from(p in Property, where: p.status == "available"), :count, :id),
      sold:      Repo.aggregate(from(p in Property, where: p.status == "sold"), :count, :id),
      rented:    Repo.aggregate(from(p in Property, where: p.status == "rented"), :count, :id)
    }
  end

  def get_property!(id) do
    Repo.get!(Property, id)
    |> Repo.preload(:owner)
  end

  def create_property(attrs) do
    case %Property{} |> Property.changeset(attrs) |> Repo.insert() do
      {:ok, property} ->
        property = Repo.preload(property, :owner)
        Phoenix.PubSub.broadcast(ElixirApp.PubSub, "properties", {:property_created, property})
        {:ok, property}
      error -> error
    end
  end

  def update_property(%Property{} = property, attrs) do
    case property |> Property.changeset(attrs) |> Repo.update() do
      {:ok, updated} -> {:ok, Repo.preload(updated, :owner)}
      error          -> error
    end
  end

  def delete_property(%Property{} = property), do: Repo.delete(property)
end
