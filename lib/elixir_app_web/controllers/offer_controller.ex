defmodule ElixirAppWeb.OfferController do
  use ElixirAppWeb, :controller
  require Logger

  alias ElixirApp.Offers
  alias ElixirApp.Offers.Offer
  alias ElixirApp.Notifications

  action_fallback ElixirAppWeb.FallbackController

  def index(conn, %{"property_id" => property_id}) do
    offers = Offers.list_offers_for_property(property_id)
    render(conn, :index, offers: offers)
  end

  def index(conn, _params) do
    offers = Offers.list_offers_by_buyer(conn.assigns.current_user.id)
    render(conn, :index, offers: offers)
  end

  def show(conn, %{"id" => id}) do
    offer = Offers.get_offer!(id)
    render(conn, :show, offer: offer)
  end

  def create(conn, %{"offer" => params}) do
    user = conn.assigns.current_user

    with :ok <- can_make_offer?(user) do
      params = Map.put(params, "buyer_id", user.id)

      with {:ok, %Offer{} = offer} <- Offers.create_offer(params) do
        # Notify the property owner (seller) in real-time.
        # `offer.property` is preloaded by create_offer so owner_id is available.
        if offer.property && offer.property.owner_id do
          buyer_name  = (offer.buyer && (offer.buyer.name || offer.buyer.email)) || "Someone"
          amount_str  = Decimal.to_string(offer.amount)
          prop_title  = offer.property.title

          # Persist so the seller sees it even if they were offline
          Notifications.create(%{
            user_id:  offer.property.owner_id,
            type:     "new_offer",
            title:    "New offer received",
            body:     "#{buyer_name} made a $#{amount_str} offer on \"#{prop_title}\"",
            metadata: %{
              offer_id:       offer.id,
              property_id:    offer.property_id,
              property_title: prop_title,
              buyer_name:     buyer_name,
              amount:         amount_str
            }
          })

          # Real-time push (only reaches online users)
          ElixirAppWeb.Endpoint.broadcast("notifications:#{offer.property.owner_id}", "new_offer", %{
            offer_id:       offer.id,
            amount:         amount_str,
            buyer_name:     buyer_name,
            property_id:    offer.property_id,
            property_title: prop_title
          })
        end

        conn
        |> put_status(:created)
        |> render(:show, offer: offer)
      end
    end
  end

  def update(conn, %{"id" => id, "offer" => params}) do
    offer = Offers.get_offer!(id)
    user  = conn.assigns.current_user

    with :ok <- authorize_offer_update(offer, params, user),
         {:ok, %Offer{} = updated} <- Offers.update_offer(offer, params) do

      # Push a real-time notification to the buyer when a seller acts on their offer.
      # We use the preloaded `offer.property` (fetched above) because `updated`
      # comes straight from Repo.update and doesn't carry associations.
      if params["status"] in ["accepted", "rejected"] do
        prop_title = offer.property.title

        # Persist so the buyer sees it even if they were offline
        Notifications.create(%{
          user_id:  updated.buyer_id,
          type:     "offer_#{updated.status}",
          title:    "Offer #{updated.status}",
          body:     "Your offer on \"#{prop_title}\" was #{updated.status}",
          metadata: %{
            offer_id:       updated.id,
            property_id:    updated.property_id,
            property_title: prop_title
          }
        })

        # Real-time push
        ElixirAppWeb.Endpoint.broadcast("notifications:#{updated.buyer_id}", "offer_update", %{
          offer_id:       updated.id,
          status:         updated.status,
          property_id:    updated.property_id,
          property_title: prop_title
        })
      end

      render(conn, :show, offer: updated)
    end
  end

  def delete(conn, %{"id" => id}) do
    offer = Offers.get_offer!(id)

    with :ok <- authorize_buyer(offer, conn.assigns.current_user),
         {:ok, %Offer{}} <- Offers.delete_offer(offer) do
      send_resp(conn, :no_content, "")
    end
  end

  defp can_make_offer?(%{role: r}) when r in ~w(buyer buyer_seller admin), do: :ok
  defp can_make_offer?(_), do: {:error, :unauthorized}

  # Buyer can withdraw their own pending offer
  defp authorize_offer_update(%{buyer_id: bid}, %{"status" => "withdrawn"}, %{id: uid})
    when bid == uid, do: :ok

  # Only sellers/buyer_sellers who own the property can accept or reject
  defp authorize_offer_update(offer, %{"status" => s}, %{id: uid, role: role})
    when s in ["accepted", "rejected"] do
    can_respond  = role in ~w(seller buyer_seller)
    owns_property = offer.property.owner_id == uid || is_nil(offer.property.owner_id)
    if can_respond && owns_property, do: :ok, else: {:error, :unauthorized}
  end

  defp authorize_offer_update(_, _, _), do: {:error, :unauthorized}

  defp authorize_buyer(%{buyer_id: bid}, %{id: uid}) when bid == uid, do: :ok
  defp authorize_buyer(_, _), do: {:error, :unauthorized}
end
