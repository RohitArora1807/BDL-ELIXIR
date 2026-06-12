defmodule ElixirAppWeb.OfferController do
  use ElixirAppWeb, :controller

  alias ElixirApp.Offers
  alias ElixirApp.Offers.Offer

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

      with {:ok, %Offer{} = offer} <- Offers.create_offer_with_notifications(params) do
        conn |> put_status(:created) |> render(:show, offer: offer)
      end
    end
  end

  def update(conn, %{"id" => id, "offer" => params}) do
    offer = Offers.get_offer!(id)
    user  = conn.assigns.current_user

    with :ok <- authorize_offer_update(offer, params, user),
         {:ok, %Offer{} = updated} <- do_update(offer, params) do
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

  defp do_update(offer, %{"status" => "accepted"}), do: Offers.accept_offer_with_notifications(offer)
  defp do_update(offer, %{"status" => "rejected"}), do: Offers.reject_offer_with_notifications(offer)
  defp do_update(offer, params),                     do: Offers.update_offer(offer, params)

  defp can_make_offer?(%{role: r}) when r in ~w(buyer buyer_seller admin), do: :ok
  defp can_make_offer?(_), do: {:error, :unauthorized}

  defp authorize_offer_update(%{buyer_id: bid}, %{"status" => "withdrawn"}, %{id: uid})
    when bid == uid, do: :ok

  defp authorize_offer_update(offer, %{"status" => s}, %{id: uid, role: role})
    when s in ["accepted", "rejected"] do
    can_respond    = role in ~w(seller buyer_seller)
    owns_property  = offer.property.owner_id == uid || is_nil(offer.property.owner_id)
    if can_respond && owns_property, do: :ok, else: {:error, :unauthorized}
  end

  defp authorize_offer_update(_, _, _), do: {:error, :unauthorized}

  defp authorize_buyer(%{buyer_id: bid}, %{id: uid}) when bid == uid, do: :ok
  defp authorize_buyer(_, _), do: {:error, :unauthorized}
end
