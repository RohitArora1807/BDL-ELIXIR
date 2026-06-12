defmodule ElixirAppWeb.OfferLive.Index do
  use ElixirAppWeb, :live_view

  alias ElixirApp.Offers
  alias ElixirApp.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user = load_user(session)
    offers       = if current_user, do: Offers.list_offers_by_buyer(current_user.id), else: []

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:offers, offers)}
  end

  defp load_user(%{"user_id" => user_id}), do: Accounts.get_user(user_id)
  defp load_user(_), do: nil

  defp status_color("accepted"), do: "green"
  defp status_color("rejected"), do: "red"
  defp status_color("pending"),  do: "yellow"
  defp status_color(_),          do: "gray"

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="page-header">
        <h1 class="page-title">My Offers</h1>
      </div>

      <div class="table-wrap">
        <%= if @offers == [] do %>
          <div class="empty-state">
            <div class="empty-state-icon">📋</div>
            <div class="empty-state-title">No offers yet</div>
            <div class="empty-state-desc">
              <.link navigate={~p"/app/properties"} style="color:var(--primary);font-weight:500;">Browse properties</.link>
              to make your first offer.
            </div>
          </div>
        <% else %>
          <table class="dt">
            <thead>
              <tr>
                <th>Property</th>
                <th>Amount</th>
                <th>Status</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody>
              <%= for offer <- @offers do %>
                <tr>
                  <td>
                    <.link navigate={~p"/app/properties/#{offer.property_id}"} style="color:var(--primary);font-weight:500;">
                      <%= if offer.property, do: offer.property.title, else: "##{offer.property_id}" %>
                    </.link>
                  </td>
                  <td style="font-weight:600;color:var(--gray-900);">$<%= offer.amount %></td>
                  <td><.badge color={status_color(offer.status)}><%= offer.status %></.badge></td>
                  <td style="color:var(--gray-500);font-size:0.85rem;">
                    <%= Calendar.strftime(offer.inserted_at, "%b %d, %Y") %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        <% end %>
      </div>
    </div>
    """
  end
end
