defmodule ElixirAppWeb.DashboardLive.Index do
  use ElixirAppWeb, :live_view

  alias ElixirApp.Properties
  alias ElixirApp.Offers
  alias ElixirApp.Notifications
  alias ElixirApp.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user = load_user(session)
    stats        = Properties.stats()
    recent       = Properties.list_recent_properties(5)

    my_offers =
      if current_user && current_user.role in ["buyer", "buyer_seller", "admin"] do
        Offers.list_offers_by_buyer(current_user.id) |> Enum.take(5)
      else
        []
      end

    my_listings =
      if current_user && current_user.role in ["seller", "buyer_seller", "admin"] do
        recent |> Enum.filter(&(&1.owner_id == current_user.id))
      else
        []
      end

    unread_count =
      if current_user do
        Notifications.list_for_user(current_user.id) |> Enum.count(& !&1.read)
      else
        0
      end

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:stats, stats)
     |> assign(:recent, recent)
     |> assign(:my_offers, my_offers)
     |> assign(:my_listings, my_listings)
     |> assign(:unread_count, unread_count)}
  end

  defp load_user(%{"user_id" => user_id}), do: Accounts.get_user(user_id)
  defp load_user(_), do: nil

  defp role_label("buyer"),        do: {"Buyer", "badge-indigo"}
  defp role_label("seller"),       do: {"Seller", "badge-yellow"}
  defp role_label("buyer_seller"), do: {"Buyer & Seller", "badge-green"}
  defp role_label("admin"),        do: {"Admin", "badge-red"}
  defp role_label(_),              do: {"Member", "badge-gray"}

  defp offer_color("accepted"), do: "badge-green"
  defp offer_color("rejected"), do: "badge-red"
  defp offer_color("pending"),  do: "badge-yellow"
  defp offer_color(_),          do: "badge-gray"

  defp status_color("available"), do: "badge-green"
  defp status_color("sold"),      do: "badge-red"
  defp status_color("rented"),    do: "badge-yellow"
  defp status_color(_),           do: "badge-gray"

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%!-- Welcome banner --%>
      <div style="background:linear-gradient(135deg,#4f46e5,#7c3aed);border-radius:var(--r-xl);padding:2rem 2.5rem;margin-bottom:2rem;color:white;display:flex;justify-content:space-between;align-items:center;">
        <div>
          <p style="font-size:0.85rem;opacity:0.8;margin-bottom:0.375rem;">Welcome back</p>
          <h1 style="font-size:1.5rem;font-weight:700;letter-spacing:-0.02em;margin-bottom:0.5rem;">
            <%= if @current_user, do: (@current_user.name || @current_user.email), else: "Guest" %>
          </h1>
          <%= if @current_user do %>
            <% {label, _cls} = role_label(@current_user.role) %>
            <span style="display:inline-flex;background:rgba(255,255,255,0.2);padding:0.2rem 0.65rem;border-radius:999px;font-size:0.75rem;font-weight:600;">
              <%= label %>
            </span>
          <% end %>
        </div>
        <div style="display:flex;gap:0.75rem;">
          <%= if @unread_count > 0 do %>
            <.link navigate={~p"/app/notifications"} style="display:flex;align-items:center;gap:0.4rem;background:rgba(255,255,255,0.15);border:1px solid rgba(255,255,255,0.25);color:white;padding:0.5rem 1rem;border-radius:var(--r);font-size:0.875rem;font-weight:500;">
              🔔 <%= @unread_count %> new
            </.link>
          <% end %>
          <.link navigate={~p"/app/properties"} style="display:flex;align-items:center;gap:0.4rem;background:white;color:#4f46e5;padding:0.5rem 1.25rem;border-radius:var(--r);font-size:0.875rem;font-weight:600;">
            Browse Properties →
          </.link>
        </div>
      </div>

      <%!-- Stats row --%>
      <div class="stats-row" style="margin-bottom:2rem;">
        <.stat_card label="Total"     value={@stats.total}     color="#4f46e5" />
        <.stat_card label="Available" value={@stats.available} color="#16a34a" />
        <.stat_card label="Sold"      value={@stats.sold}      color="#dc2626" />
        <.stat_card label="Rented"    value={@stats.rented}    color="#d97706" />
      </div>

      <%!-- Two-column section --%>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:1.5rem;margin-bottom:1.5rem;">

        <%!-- Recent Listings --%>
        <div class="card">
          <div style="padding:1.25rem 1.5rem;border-bottom:1px solid var(--gray-100);display:flex;justify-content:space-between;align-items:center;">
            <p style="font-size:0.875rem;font-weight:700;color:var(--gray-900);">Recent Listings</p>
            <.link navigate={~p"/app/properties"} style="font-size:0.78rem;color:var(--primary);font-weight:500;">
              View all →
            </.link>
          </div>
          <div style="padding:0.5rem 0;">
            <%= if @recent == [] do %>
              <div class="empty-state" style="padding:2rem;">
                <div class="empty-state-icon">🏘</div>
                <div class="empty-state-title">No properties yet</div>
              </div>
            <% else %>
              <%= for prop <- @recent do %>
                <.link navigate={~p"/app/properties/#{prop.id}"} style="display:flex;align-items:center;gap:0.875rem;padding:0.75rem 1.5rem;transition:background 0.15s;" class="dash-row">
                  <div style={"width:36px;height:36px;border-radius:var(--r-sm);display:flex;align-items:center;justify-content:center;font-size:1.1rem;flex-shrink:0;background:#{if prop.type == "house", do: "#eef2ff", else: "#f5f3ff"};"}>
                    <%= if prop.type == "house", do: "🏠", else: "🏢" %>
                  </div>
                  <div style="flex:1;min-width:0;">
                    <p style="font-size:0.85rem;font-weight:600;color:var(--gray-900);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
                      <%= prop.title %>
                    </p>
                    <p style="font-size:0.75rem;color:var(--gray-400);">$<%= prop.price %> · <%= prop.location %></p>
                  </div>
                  <span class={"badge #{status_color(prop.status)}"} style="flex-shrink:0;"><%= prop.status %></span>
                </.link>
              <% end %>
            <% end %>
          </div>
        </div>

        <%!-- My Activity --%>
        <div class="card">
          <div style="padding:1.25rem 1.5rem;border-bottom:1px solid var(--gray-100);">
            <p style="font-size:0.875rem;font-weight:700;color:var(--gray-900);">My Activity</p>
          </div>
          <div style="padding:0.5rem 0;">

            <%!-- Buyer: my recent offers --%>
            <%= if @current_user && @current_user.role in ["buyer", "buyer_seller", "admin"] do %>
              <div style="padding:0.75rem 1.5rem 0.375rem;">
                <p style="font-size:0.72rem;font-weight:600;text-transform:uppercase;letter-spacing:0.05em;color:var(--gray-400);">My Offers</p>
              </div>
              <%= if @my_offers == [] do %>
                <p style="padding:0.5rem 1.5rem 1rem;font-size:0.85rem;color:var(--gray-400);">
                  No offers yet.
                  <.link navigate={~p"/app/properties"} style="color:var(--primary);">Browse listings</.link>
                </p>
              <% else %>
                <%= for offer <- @my_offers do %>
                  <.link navigate={~p"/app/properties/#{offer.property_id}"} style="display:flex;justify-content:space-between;align-items:center;padding:0.625rem 1.5rem;transition:background 0.15s;" class="dash-row">
                    <div>
                      <p style="font-size:0.85rem;font-weight:500;color:var(--gray-800);">
                        <%= if offer.property, do: offer.property.title, else: "Property ##{offer.property_id}" %>
                      </p>
                      <p style="font-size:0.75rem;color:var(--gray-400);">$<%= offer.amount %></p>
                    </div>
                    <span class={"badge #{offer_color(offer.status)}"}>
                      <%= offer.status %>
                    </span>
                  </.link>
                <% end %>
                <div style="padding:0.5rem 1.5rem;">
                  <.link navigate={~p"/app/offers"} style="font-size:0.78rem;color:var(--primary);font-weight:500;">
                    View all offers →
                  </.link>
                </div>
              <% end %>
            <% end %>

            <%!-- Seller: my listings --%>
            <%= if @current_user && @current_user.role in ["seller", "buyer_seller", "admin"] do %>
              <div style="padding:0.75rem 1.5rem 0.375rem;">
                <p style="font-size:0.72rem;font-weight:600;text-transform:uppercase;letter-spacing:0.05em;color:var(--gray-400);">My Listings</p>
              </div>
              <%= if @my_listings == [] do %>
                <p style="padding:0.5rem 1.5rem 0.5rem;font-size:0.85rem;color:var(--gray-400);">
                  No listings yet.
                  <.link navigate={~p"/app/properties/new"} style="color:var(--primary);">Add one</.link>
                </p>
              <% else %>
                <%= for prop <- @my_listings do %>
                  <.link navigate={~p"/app/properties/#{prop.id}"} style="display:flex;justify-content:space-between;align-items:center;padding:0.625rem 1.5rem;transition:background 0.15s;" class="dash-row">
                    <p style="font-size:0.85rem;font-weight:500;color:var(--gray-800);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:180px;">
                      <%= prop.title %>
                    </p>
                    <span class={"badge #{status_color(prop.status)}"}>
                      <%= prop.status %>
                    </span>
                  </.link>
                <% end %>
              <% end %>
            <% end %>

            <%!-- Buyer-only message if no seller role --%>
            <%= if @current_user && @current_user.role == "buyer" && @my_offers == [] do %>
              <div style="padding:1rem 1.5rem;">
                <p style="font-size:0.85rem;color:var(--gray-500);">Start by browsing available properties and submitting an offer.</p>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <%!-- Quick actions --%>
      <div class="card card-pad">
        <p style="font-size:0.875rem;font-weight:700;color:var(--gray-900);margin-bottom:1rem;">Quick Actions</p>
        <div style="display:flex;gap:0.75rem;flex-wrap:wrap;">
          <.link navigate={~p"/app/properties"} class="btn btn-primary btn-sm">
            🏘 Browse Properties
          </.link>
          <%= if @current_user && @current_user.role in ["seller", "buyer_seller", "admin"] do %>
            <.link patch={~p"/app/properties/new"} class="btn btn-ghost btn-sm">
              + List a Property
            </.link>
          <% end %>
          <.link navigate={~p"/app/offers"} class="btn btn-ghost btn-sm">
            📋 My Offers
          </.link>
          <.link navigate={~p"/app/notifications"} class="btn btn-ghost btn-sm">
            🔔 Notifications
            <%= if @unread_count > 0 do %>
              <span class="unread-badge" style="margin-left:0.25rem;"><%= @unread_count %></span>
            <% end %>
          </.link>
        </div>
      </div>
    </div>

    <style>
      .dash-row:hover { background: var(--gray-50); }
    </style>
    """
  end
end
