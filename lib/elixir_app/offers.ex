defmodule ElixirApp.Offers do
  import Ecto.Query, warn: false
  alias ElixirApp.Repo
  alias ElixirApp.Offers.Offer
  alias ElixirApp.Notifications
  alias ElixirApp.Workers.{NewOfferEmailWorker, OfferUpdateEmailWorker}

  def list_all_offers do
    Offer
    |> order_by([o], desc: o.inserted_at)
    |> preload([:property, :buyer])
    |> Repo.all()
  end

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

  # High-level: create + notify seller + email
  def create_offer_with_notifications(attrs) do
    case create_offer(attrs) do
      {:ok, offer} ->
        dispatch_new_offer_events(offer)
        {:ok, offer}
      error -> error
    end
  end

  def update_offer(%Offer{} = offer, attrs) do
    offer |> Offer.changeset(attrs) |> Repo.update()
  end

  def accept_offer(%Offer{} = offer), do: update_offer(offer, %{status: "accepted"})
  def reject_offer(%Offer{} = offer), do: update_offer(offer, %{status: "rejected"})

  # High-level: update + notify buyer + email
  def accept_offer_with_notifications(%Offer{} = offer) do
    case accept_offer(offer) do
      {:ok, updated} ->
        dispatch_offer_update_events(offer, "accepted")
        {:ok, updated}
      error -> error
    end
  end

  def reject_offer_with_notifications(%Offer{} = offer) do
    case reject_offer(offer) do
      {:ok, updated} ->
        dispatch_offer_update_events(offer, "rejected")
        {:ok, updated}
      error -> error
    end
  end

  def delete_offer(%Offer{} = offer), do: Repo.delete(offer)

  # ---- private side-effect helpers ----

  defp dispatch_new_offer_events(offer) do
    with %{owner_id: owner_id} when not is_nil(owner_id) <- offer.property do
      buyer_name = (offer.buyer && (offer.buyer.name || offer.buyer.email)) || "Someone"
      amount_str = Decimal.to_string(offer.amount)
      prop_title = offer.property.title

      Notifications.create(%{
        user_id:  owner_id,
        type:     "new_offer",
        title:    "New offer received",
        body:     "#{buyer_name} made a $#{amount_str} offer on \"#{prop_title}\"",
        metadata: %{offer_id: offer.id, property_id: offer.property_id,
                    property_title: prop_title, buyer_name: buyer_name, amount: amount_str}
      })

      Phoenix.PubSub.broadcast(ElixirApp.PubSub, "notifications:#{owner_id}", %{
        event: "new_offer", offer_id: offer.id, amount: amount_str,
        buyer_name: buyer_name, property_id: offer.property_id, property_title: prop_title
      })

      Phoenix.PubSub.broadcast(ElixirApp.PubSub, "property:#{offer.property_id}", {:new_offer, offer})

      %{seller_id: owner_id, buyer_name: buyer_name, property_title: prop_title, amount: amount_str}
      |> NewOfferEmailWorker.new()
      |> Oban.insert()
    end
    :ok
  end

  defp dispatch_offer_update_events(offer, status) do
    if offer.property do
      prop_title = offer.property.title

      Notifications.create(%{
        user_id:  offer.buyer_id,
        type:     "offer_#{status}",
        title:    "Offer #{status}",
        body:     "Your offer on \"#{prop_title}\" was #{status}",
        metadata: %{offer_id: offer.id, property_id: offer.property_id, property_title: prop_title}
      })

      Phoenix.PubSub.broadcast(ElixirApp.PubSub, "notifications:#{offer.buyer_id}", %{
        event: "offer_update", offer_id: offer.id, status: status,
        property_id: offer.property_id, property_title: prop_title
      })

      Phoenix.PubSub.broadcast(ElixirApp.PubSub, "property:#{offer.property_id}", {:offer_updated, offer})

      %{buyer_id: offer.buyer_id, property_title: prop_title, status: status}
      |> OfferUpdateEmailWorker.new()
      |> Oban.insert()
    end
    :ok
  end
end
