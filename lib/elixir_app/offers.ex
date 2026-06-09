defmodule ElixirApp.Offers do
  import Ecto.Query, warn: false
  alias ElixirApp.Repo
  alias ElixirApp.Offers.Offer

  def list_offers_for_property(property_id) do
    Offer
    |> where([o], o.property_id == ^property_id)
    |> order_by([o], desc: o.inserted_at)
    |> preload([:property, :buyer])
    |> Repo.all()
  end

  def list_offers_by_buyer(buyer_id) do
    Offer
    |> where([o], o.buyer_id == ^buyer_id)
    |> order_by([o], desc: o.inserted_at)
    |> preload([:property, :buyer])
    |> Repo.all()
  end

  def get_offer!(id), do: Repo.get!(Offer, id) |> Repo.preload([:property, :buyer])

  def create_offer(attrs) do
    case %Offer{} |> Offer.changeset(attrs) |> Repo.insert() do
      {:ok, offer} -> {:ok, Repo.preload(offer, [:property, :buyer])}
      error        -> error
    end
  end

  def update_offer(%Offer{} = offer, attrs) do
    offer
    |> Offer.changeset(attrs)
    |> Repo.update()
  end

  def delete_offer(%Offer{} = offer), do: Repo.delete(offer)
end
