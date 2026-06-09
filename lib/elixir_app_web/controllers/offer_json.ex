defmodule ElixirAppWeb.OfferJSON do
  alias ElixirApp.Offers.Offer

  def index(%{offers: offers}), do: %{data: Enum.map(offers, &data/1)}

  def show(%{offer: offer}), do: %{data: data(offer)}

  defp data(%Offer{} = o) do
    %{
      id:          o.id,
      buyer_id:    o.buyer_id,
      property_id: o.property_id,
      amount:      o.amount,
      status:      o.status,
      message:     o.message,
      expires_at:  o.expires_at,
      inserted_at: o.inserted_at,
      buyer:       buyer_data(o.buyer),
      property:    property_data(o.property)
    }
  end

  defp buyer_data(%{id: id, name: name, email: email}), do: %{id: id, name: name, email: email}
  defp buyer_data(_), do: nil

  defp property_data(%{id: id, title: title, price: price, location: location, status: status}) do
    %{id: id, title: title, price: price, location: location, status: status}
  end
  defp property_data(_), do: nil
end
