defmodule ElixirAppWeb.PropertyLive.Show do
  use ElixirAppWeb, :live_view

  alias ElixirApp.Properties
  alias ElixirApp.Offers
  alias ElixirApp.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user = load_user(session)

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:show_edit_form, false)
     |> assign(:edit_error, nil)
     |> assign(:confirm_delete, false)
     |> assign(:mapbox_token, Application.get_env(:elixir_app, :mapbox_token, ""))
     |> assign(:offers, [])
     |> assign(:loading, true)}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    property  = Properties.get_property!(id)
    show_edit = socket.assigns.live_action == :edit

    socket =
      socket
      |> assign(:property, property)
      |> assign(:show_edit_form, show_edit)
      |> assign(:page_title, property.title)

    if connected?(socket) do
      # WS phase: subscribe to real-time updates + load secondary data
      Phoenix.PubSub.subscribe(ElixirApp.PubSub, "property:#{id}")
offers = Offers.list_offers_for_property(id)
      {:noreply, socket |> assign(:offers, offers) |> assign(:loading, false)}
    else
      # HTTP phase: render the page immediately with property info only.
      # Offers are secondary — no point hitting the DB twice before WS connects.
      {:noreply, socket}
    end
  end

  # ---- Messages ----

  @impl true
  def handle_info({:offer_submitted, _offer}, socket) do
    offers = Offers.list_offers_for_property(socket.assigns.property.id)
    {:noreply, socket |> assign(:offers, offers) |> put_flash(:info, "Offer submitted! The seller has been notified.")}
  end

  # Another user submitted an offer on this property (via PubSub broadcast).
  # Refresh the offers panel live — no page reload needed.
  def handle_info({:new_offer, _offer}, socket) do
    offers = Offers.list_offers_for_property(socket.assigns.property.id)
    {:noreply, assign(socket, :offers, offers)}
  end

  # ---- Offer events ----

  @impl true
  def handle_event("accept_offer", %{"id" => offer_id}, socket) do
    with :ok <- assert_owner(socket) do
      offer    = Offers.get_offer!(offer_id)
      {:ok, _} = Offers.accept_offer_with_notifications(offer)
      offers   = Offers.list_offers_for_property(socket.assigns.property.id)
      property = Properties.get_property!(socket.assigns.property.id)

      # Push the fresh property directly into OfferFormComponent.
      # The component's update/2 fires immediately — no parent re-render needed.
      send_update(ElixirAppWeb.PropertyLive.OfferFormComponent,
        id: "offer-form",
        property: property,
        current_user: socket.assigns.current_user
      )

      {:noreply, socket |> assign(:offers, offers) |> assign(:property, property) |> put_flash(:info, "Offer accepted. Buyer notified.")}
    else
      _ -> {:noreply, put_flash(socket, :error, "Not authorized.")}
    end
  end

  def handle_event("reject_offer", %{"id" => offer_id}, socket) do
    with :ok <- assert_owner(socket) do
      offer = Offers.get_offer!(offer_id)
      {:ok, _} = Offers.reject_offer_with_notifications(offer)
      offers = Offers.list_offers_for_property(socket.assigns.property.id)
      {:noreply, socket |> assign(:offers, offers) |> put_flash(:info, "Offer rejected. Buyer notified.")}
    else
      _ -> {:noreply, put_flash(socket, :error, "Not authorized.")}
    end
  end

  # ---- Edit events ----

  def handle_event("show_edit_form", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/properties/#{socket.assigns.property.id}/edit")}
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/properties/#{socket.assigns.property.id}")}
  end

  def handle_event("update_property", params, socket) do
    with :ok <- assert_owner(socket) do
      property = socket.assigns.property

      attrs = %{
        title:       params["title"],
        description: params["description"],
        price:       params["price"],
        location:    params["location"],
        bedrooms:    parse_int(params["bedrooms"]),
        bathrooms:   parse_int(params["bathrooms"]),
        area:        parse_float(params["area"]),
        type:        params["type"],
        status:      params["status"]
      }

      case Properties.update_property(property, attrs) do
        {:ok, updated} ->
          {:noreply,
           socket
           |> assign(:property, updated)
           |> push_patch(to: ~p"/app/properties/#{updated.id}")
           |> put_flash(:info, "Property updated.")}

        {:error, changeset} ->
          msg = changeset.errors |> Enum.map(fn {k, {v, _}} -> "#{k} #{v}" end) |> Enum.join(", ")
          {:noreply, assign(socket, :edit_error, msg)}
      end
    else
      _ -> {:noreply, put_flash(socket, :error, "Not authorized.")}
    end
  end

  # ---- Delete events ----

  def handle_event("confirm_delete", _params, socket) do
    {:noreply, assign(socket, :confirm_delete, true)}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, :confirm_delete, false)}
  end

  def handle_event("delete_property", _params, socket) do
    with :ok <- assert_owner(socket) do
      {:ok, _} = Properties.delete_property(socket.assigns.property)
      {:noreply, socket |> put_flash(:info, "Property deleted.") |> push_navigate(to: ~p"/app/properties")}
    else
      _ -> {:noreply, put_flash(socket, :error, "Not authorized.")}
    end
  end

  # ---- Auth helpers ----

  defp load_user(%{"user_id" => user_id}), do: Accounts.get_user(user_id)
  defp load_user(_), do: nil

  defp assert_owner(socket) do
    if owns_property?(socket.assigns.current_user, socket.assigns.property),
      do: :ok,
      else: {:error, :unauthorized}
  end

  defp owns_property?(nil, _property), do: false
  defp owns_property?(user, property), do: user.id == property.owner_id

  # ---- Parse helpers ----

  defp parse_int(nil), do: nil
  defp parse_int(""),  do: nil
  defp parse_int(v),   do: String.to_integer(v)

  defp parse_float(nil), do: nil
  defp parse_float(""),  do: nil
  defp parse_float(v) do
    case Float.parse(v) do
      {f, _} -> f
      :error  -> nil
    end
  end

  # ---- Color helpers ----

  defp status_color("available"), do: "green"
  defp status_color("sold"),      do: "red"
  defp status_color("rented"),    do: "yellow"
  defp status_color(_),           do: "gray"

  defp offer_color("accepted"), do: "green"
  defp offer_color("rejected"), do: "red"
  defp offer_color("pending"),  do: "yellow"
  defp offer_color(_),          do: "gray"

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.link navigate={~p"/app/properties"} class="back-link">← Back to Properties</.link>

      <%!-- Edit Modal --%>
      <%= if @show_edit_form do %>
        <div class="modal-overlay">
          <div class="modal">
            <div class="modal-header">
              <h2 class="modal-title">Edit Property</h2>
              <button phx-click="cancel_edit" class="modal-close">✕</button>
            </div>
            <div class="modal-body">
              <%= if @edit_error do %>
                <div class="alert alert-error"><%= @edit_error %></div>
              <% end %>
              <form phx-submit="update_property">
                <div class="form-grid">
                  <div class="form-row-full">
                    <label class="form-label">Title *</label>
                    <input type="text" name="title" required value={@property.title} class="form-input" />
                  </div>
                  <div class="form-row-full">
                    <label class="form-label">Location *</label>
                    <input type="text" name="location" required value={@property.location} class="form-input" />
                  </div>
                  <div>
                    <label class="form-label">Price ($) *</label>
                    <input type="number" name="price" required min="1" value={@property.price} class="form-input" />
                  </div>
                  <div>
                    <label class="form-label">Type</label>
                    <select name="type" class="form-input">
                      <option value="house"     selected={@property.type == "house"}>House</option>
                      <option value="apartment" selected={@property.type == "apartment"}>Apartment</option>
                    </select>
                  </div>
                  <div>
                    <label class="form-label">Bedrooms</label>
                    <input type="number" name="bedrooms" min="0" value={@property.bedrooms} class="form-input" />
                  </div>
                  <div>
                    <label class="form-label">Bathrooms</label>
                    <input type="number" name="bathrooms" min="0" value={@property.bathrooms} class="form-input" />
                  </div>
                  <div>
                    <label class="form-label">Area (sqft)</label>
                    <input type="number" name="area" min="0" step="0.1" value={@property.area} class="form-input" />
                  </div>
                  <div>
                    <label class="form-label">Status</label>
                    <select name="status" class="form-input">
                      <option value="available" selected={@property.status == "available"}>Available</option>
                      <option value="rented"    selected={@property.status == "rented"}>Rented</option>
                      <option value="sold"      selected={@property.status == "sold"}>Sold</option>
                    </select>
                  </div>
                  <div class="form-row-full">
                    <label class="form-label">Description</label>
                    <textarea name="description" rows="3" class="form-input"><%= @property.description %></textarea>
                  </div>
                </div>
                <div class="form-actions">
                  <button type="submit" class="btn btn-primary btn-block">Save Changes</button>
                  <button type="button" phx-click="cancel_edit" class="btn btn-ghost">Cancel</button>
                </div>
              </form>
            </div>
          </div>
        </div>
      <% end %>

      <%!-- Two-column detail layout --%>
      <div class="detail-grid">
        <%!-- Left: Property card --%>
        <div class="card" style="overflow:hidden;">
          <%= if @property.image_path do %>
            <img src={@property.image_path} alt={@property.title} class="prop-image" />
          <% else %>
            <div class={"prop-hero #{if @property.type == "house", do: "prop-hero-house", else: "prop-hero-apt"}"}>
              <%= if @property.type == "house", do: "🏠", else: "🏢" %>
            </div>
          <% end %>
          <div class="detail-body">
            <div style="display:flex;justify-content:space-between;align-items:flex-start;gap:0.75rem;margin-bottom:0.75rem;">
              <h1 style="font-size:1.25rem;font-weight:700;color:var(--gray-900);letter-spacing:-0.02em;line-height:1.3;">
                <%= @property.title %>
              </h1>
              <.badge color={status_color(@property.status)}><%= @property.status %></.badge>
            </div>

            <div style="font-size:0.875rem;color:var(--gray-500);margin-bottom:0.5rem;">
              📍 <%= @property.location %>
            </div>

            <%= if @property.owner do %>
              <div style="font-size:0.8rem;color:var(--gray-400);margin-bottom:0.75rem;">
                Listed by <%= @property.owner.name || @property.owner.email %>
                <%= if owns_property?(@current_user, @property) do %>
                  <span class="your-listing-pill">Your Listing</span>
                <% end %>
              </div>
            <% end %>

            <div class="price-tag">$<%= @property.price %></div>

            <div class="detail-meta">
              <span class="detail-meta-item">🛏 <%= @property.bedrooms %> bedrooms</span>
              <span class="detail-meta-item">🚿 <%= @property.bathrooms %> bathrooms</span>
              <span class="detail-meta-item">📐 <%= @property.area %> sqft</span>
            </div>

            <%= if @property.description do %>
              <p style="font-size:0.9rem;color:var(--gray-600);line-height:1.65;margin-bottom:1.25rem;">
                <%= @property.description %>
              </p>
            <% end %>

            <div class="divider"></div>

            <%!-- Owner actions --%>
            <%= if owns_property?(@current_user, @property) do %>
              <div class="action-row" style="margin-bottom:1rem;">
                <button phx-click="show_edit_form" class="btn btn-primary btn-sm">
                  ✎ Edit Listing
                </button>
                <%= if !@confirm_delete do %>
                  <button phx-click="confirm_delete" class="btn btn-danger-soft btn-sm">
                    🗑 Delete
                  </button>
                <% else %>
                  <div class="delete-confirm">
                    <span>Delete this listing?</span>
                    <button phx-click="delete_property" class="btn btn-danger btn-sm">Yes, delete</button>
                    <button phx-click="cancel_delete" class="btn btn-ghost btn-sm">Cancel</button>
                  </div>
                <% end %>
              </div>
            <% end %>

            <%!-- Offer form — managed entirely by OfferFormComponent --%>
            <.live_component
              module={ElixirAppWeb.PropertyLive.OfferFormComponent}
              id="offer-form"
              property={@property}
              current_user={@current_user}
            />
          </div>

          <%!-- Mapbox map — JS hook mounts here, geocodes @property.location --%>
          <%= if @mapbox_token != "" && @property.location do %>
            <div style="padding:0 1.5rem 0.5rem;border-top:1px solid var(--gray-100);margin-top:0.5rem;">
              <p style="font-size:0.75rem;font-weight:600;color:var(--gray-500);padding:0.75rem 0 0.5rem;text-transform:uppercase;letter-spacing:0.05em;">
                📍 Location Map
              </p>
            </div>
            <div
              id="property-map"
              phx-hook="MapboxMap"
              data-token={@mapbox_token}
              data-location={@property.location}
              style="height:280px;background:#e2e8f0;"
            ></div>
          <% end %>
        </div>

        <%!-- Right: Offers panel --%>
        <div class="card card-pad">
          <p style="font-size:0.875rem;font-weight:700;color:var(--gray-900);margin-bottom:1rem;">
            Offers
            <span style="font-size:0.75rem;font-weight:500;color:var(--gray-400);margin-left:0.35rem;">
              (<%= length(@offers) %>)
            </span>
          </p>

          <%= if @loading do %>
            <div style="display:flex;flex-direction:column;gap:0.75rem;">
              <%= for _ <- 1..2 do %>
                <div style="height:56px;background:var(--gray-100);border-radius:var(--r);animation:pulse 1.5s ease-in-out infinite;"></div>
              <% end %>
            </div>
          <% else %>
          <%= if @offers == [] do %>
            <div class="empty-state" style="padding:2rem 1rem;">
              <div class="empty-state-icon">📭</div>
              <div class="empty-state-title">No offers yet</div>
            </div>
          <% else %>
            <div>
              <%= for offer <- @offers do %>
                <div class="offer-item">
                  <div class="offer-item-header">
                    <span class="offer-amount">$<%= offer.amount %></span>
                    <.badge color={offer_color(offer.status)}><%= offer.status %></.badge>
                  </div>
                  <%= if offer.buyer do %>
                    <div class="offer-buyer">by <%= offer.buyer.name || offer.buyer.email %></div>
                  <% end %>
                  <%= if owns_property?(@current_user, @property) && offer.status == "pending" do %>
                    <div class="offer-actions">
                      <button phx-click="accept_offer" phx-value-id={offer.id} class="btn btn-success btn-sm" style="flex:1;">
                        Accept
                      </button>
                      <button phx-click="reject_offer" phx-value-id={offer.id} class="btn btn-danger btn-sm" style="flex:1;">
                        Reject
                      </button>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
