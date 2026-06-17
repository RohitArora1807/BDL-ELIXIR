defmodule ElixirAppWeb.AshPropertyLive.Show do
  use ElixirAppWeb, :live_view

  alias ElixirApp.RealEstate.{Property, Offer}
  alias ElixirApp.Accounts

  @impl true
  def mount(_params, session, socket) do
    {:ok,
     socket
     |> assign(:current_user, load_user(session))
     |> assign(:offers, [])
     |> assign(:show_offer_form, false)}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    actor = socket.assigns.current_user

    case Ash.get(Property, id, domain: ElixirApp.RealEstate, actor: actor, load: [:owner]) do
      {:ok, nil} ->
        {:noreply,
         socket
         |> put_flash(:error, "Property not found.")
         |> push_navigate(to: ~p"/app/ash/properties")}

      {:ok, property} ->
        offers = list_offers(property.id, actor)
        {:noreply,
         socket
         |> assign(:property, property)
         |> assign(:offers, offers)
         |> assign(:page_title, property.title)}

      {:error, %Ash.Error.Forbidden{}} ->
        {:noreply,
         socket
         |> put_flash(:error, "Access denied by Ash policy.")
         |> push_navigate(to: ~p"/app/ash/properties")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Something went wrong.")
         |> push_navigate(to: ~p"/app/ash/properties")}
    end
  end

  # ── Submit offer via Ash.create ──────────────────────────────────────────

  @impl true
  def handle_event("submit_offer", %{"amount" => amount, "message" => message}, socket) do
    actor    = socket.assigns.current_user
    property = socket.assigns.property

    case Ash.create(Offer, %{amount: amount, property_id: property.id, message: message},
           domain: ElixirApp.RealEstate,
           actor: actor
         ) do
      {:ok, _offer} ->
        offers = list_offers(property.id, actor)
        {:noreply,
         socket
         |> put_flash(:info, "Offer submitted via Ash.create!")
         |> assign(:offers, offers)
         |> assign(:show_offer_form, false)}

      {:error, %Ash.Error.Forbidden{}} ->
        {:noreply, put_flash(socket, :error, "Ash policy denied — only buyers can submit offers.")}

      {:error, error} ->
        msg = case error do
          %Ash.Error.Invalid{errors: [%{message: m} | _]} -> m
          _ -> "Invalid offer — check amount."
        end
        {:noreply, put_flash(socket, :error, msg)}
    end
  end

  def handle_event("toggle_offer_form", _params, socket) do
    {:noreply, assign(socket, :show_offer_form, !socket.assigns.show_offer_form)}
  end

  # ── Accept / Reject offers ───────────────────────────────────────────────

  def handle_event("accept_offer", %{"id" => id}, socket) do
    run_offer_action(id, :accept, "accepted", socket)
  end

  def handle_event("reject_offer", %{"id" => id}, socket) do
    run_offer_action(id, :reject, "rejected", socket)
  end

  def handle_event("delete", _params, socket) do
    case Ash.destroy(socket.assigns.property,
           domain: ElixirApp.RealEstate,
           actor: socket.assigns.current_user
         ) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "Property deleted by Ash.")
         |> push_navigate(to: ~p"/app/ash/properties")}

      {:error, %Ash.Error.Forbidden{}} ->
        {:noreply, put_flash(socket, :error, "Ash policy denied: only admins can delete.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Delete failed.")}
    end
  end

  # ── Helpers ──────────────────────────────────────────────────────────────

  defp run_offer_action(id, action, label, socket) do
    actor = socket.assigns.current_user

    with {:ok, offer} <- Ash.get(Offer, id, domain: ElixirApp.RealEstate, actor: actor),
         {:ok, _}     <- Ash.update(offer, %{}, action: action, domain: ElixirApp.RealEstate, actor: actor) do
      offers = list_offers(socket.assigns.property.id, actor)
      {:noreply,
       socket
       |> put_flash(:info, "Offer #{label}.")
       |> assign(:offers, offers)}
    else
      {:error, %Ash.Error.Forbidden{}} ->
        {:noreply, put_flash(socket, :error, "Ash policy denied.")}
      _ ->
        {:noreply, put_flash(socket, :error, "Action failed.")}
    end
  end

  defp list_offers(property_id, actor) do
    Offer
    |> Ash.Query.for_read(:for_property, %{property_id: property_id}, actor: actor)
    |> Ash.read!(domain: ElixirApp.RealEstate, actor: actor, load: [:buyer])
  end

  defp load_user(%{"user_id" => id}), do: Accounts.get_user(id)
  defp load_user(_), do: nil

  defp owns?(nil, _),      do: false
  defp owns?(user, prop),  do: user.id == prop.owner_id

  defp is_admin?(nil),     do: false
  defp is_admin?(user),    do: user.role == "admin"

  defp is_buyer?(nil),     do: false
  defp is_buyer?(user),    do: user.role == "buyer"

  defp status_color("available"), do: "green"
  defp status_color("sold"),      do: "red"
  defp status_color(_),           do: "yellow"

  defp offer_color("accepted"), do: "green"
  defp offer_color("rejected"), do: "red"
  defp offer_color(_),          do: "yellow"

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.link navigate={~p"/app/ash/properties"} class="back-link" style="color:#7c3aed;">
        ← Back to Ash Properties
      </.link>

      <!-- Ash banner -->
      <div style="background:linear-gradient(135deg,#7c3aed,#6d28d9);color:white;border-radius:10px;padding:0.75rem 1.25rem;margin:0.75rem 0 1.25rem;display:flex;justify-content:space-between;align-items:center;">
        <div style="font-size:0.8rem;">
          ⚡ Loaded with <code style="background:rgba(255,255,255,0.15);padding:0.1rem 0.35rem;border-radius:3px;">Ash.get!(Property, id, actor: current_user, load: [:owner])</code>
        </div>
        <.link navigate={~p"/app/properties/#{@property.owner_id}"} style="color:white;opacity:0.7;font-size:0.75rem;">
          View Ecto version →
        </.link>
      </div>

      <div class="detail-grid">
        <!-- Left: property card -->
        <div class="card" style="border-top:4px solid #7c3aed;overflow:hidden;">

          <div style="background:linear-gradient(135deg,#f5f3ff,#ede9fe);min-height:180px;display:flex;align-items:center;justify-content:center;font-size:4rem;">
            <%= if @property.type == "house", do: "🏠", else: "🏢" %>
          </div>

          <div class="detail-body">
            <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:0.75rem;">
              <h1 style="font-size:1.25rem;font-weight:700;color:#1e293b;line-height:1.3;">
                <%= @property.title %>
              </h1>
              <.badge color={status_color(@property.status)}><%= @property.status %></.badge>
            </div>

            <div style="font-size:0.875rem;color:#64748b;margin-bottom:0.5rem;">
              📍 <%= @property.location %>
            </div>

            <%= if @property.owner do %>
              <div style="font-size:0.8rem;color:#7c3aed;margin-bottom:0.75rem;">
                ⚡ Owner loaded by Ash:
                <strong><%= @property.owner.email %></strong>
                (role: <%= @property.owner.role %>)
                <%= if owns?(@current_user, @property) do %>
                  <span style="background:#7c3aed;color:white;font-size:0.65rem;padding:0.15rem 0.5rem;border-radius:999px;margin-left:0.35rem;">Your Listing</span>
                <% end %>
              </div>
            <% end %>

            <div class="price-tag" style="color:#7c3aed;">$<%= @property.price %></div>

            <div class="detail-meta">
              <span class="detail-meta-item">🛏 <%= @property.bedrooms %> bedrooms</span>
              <span class="detail-meta-item">🚿 <%= @property.bathrooms %> bathrooms</span>
              <span class="detail-meta-item">📐 <%= @property.area %> sqft</span>
            </div>

            <%= if @property.description do %>
              <p style="font-size:0.9rem;color:#475569;line-height:1.65;margin-bottom:1.25rem;">
                <%= @property.description %>
              </p>
            <% end %>

            <div class="divider"></div>

            <!-- Actions -->
            <div style="display:flex;gap:0.75rem;margin-bottom:1rem;flex-wrap:wrap;">
              <%= if owns?(@current_user, @property) || is_admin?(@current_user) do %>
                <.link
                  navigate={~p"/app/ash/properties/#{@property.id}/edit"}
                  class="btn btn-primary btn-sm"
                  style="background:#7c3aed;border-color:#7c3aed;"
                >
                  ✎ Edit (Ash Form)
                </.link>
              <% end %>

              <%= if is_admin?(@current_user) do %>
                <button
                  phx-click="delete"
                  data-confirm="Delete this Ash property?"
                  class="btn btn-danger-soft btn-sm"
                >
                  🗑 Delete (Ash)
                </button>
              <% end %>
            </div>

            <!-- Policy explanation -->
            <div style="background:#f5f3ff;border:1px solid #ddd6fe;border-radius:8px;padding:0.75rem;font-size:0.75rem;color:#5b21b6;">
              <strong>Policy in effect for your role (<%= if @current_user, do: @current_user.role, else: "guest" %>):</strong>
              <ul style="margin:0.4rem 0 0;padding-left:1.2rem;line-height:1.8;">
                <li>Read → ✅ always allowed</li>
                <li>Edit → <%= if owns?(@current_user, @property) || is_admin?(@current_user), do: "✅ allowed (you own it or are admin)", else: "❌ forbidden (not your listing)" %></li>
                <li>Delete → <%= if is_admin?(@current_user), do: "✅ allowed (admin)", else: "❌ forbidden (admin only)" %></li>
              </ul>
            </div>
          </div>
        </div>

        <!-- Right: Offers panel -->
        <div class="card card-pad">
          <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:1rem;">
            <p style="font-size:0.875rem;font-weight:700;color:#1e293b;margin:0;">
              Offers
              <span style="font-size:0.75rem;font-weight:500;color:#94a3b8;margin-left:0.35rem;">
                (<%= length(@offers) %>)
              </span>
            </p>
            <%= if is_buyer?(@current_user) && @property.status == "available" do %>
              <button
                phx-click="toggle_offer_form"
                class="btn btn-primary btn-sm"
                style="background:#7c3aed;border-color:#7c3aed;"
              >
                <%= if @show_offer_form, do: "Cancel", else: "+ Submit Offer" %>
              </button>
            <% end %>
          </div>

          <!-- Teaching note -->
          <div style="background:#f5f3ff;border:1px solid #ddd6fe;border-radius:8px;padding:0.65rem 0.85rem;margin-bottom:1rem;font-size:0.72rem;color:#5b21b6;">
            ⚡ <strong>Ash.create(Offer, &#37;&#123;...&#125;, actor: current_user)</strong> — buyer_id set automatically, policy checked, validation runs. No manual auth code.
          </div>

          <!-- Offer form -->
          <%= if @show_offer_form do %>
            <div style="background:#faf5ff;border:1px solid #ddd6fe;border-radius:8px;padding:1rem;margin-bottom:1rem;">
              <form phx-submit="submit_offer" style="display:flex;flex-direction:column;gap:0.65rem;">
                <div>
                  <label style="font-size:0.78rem;font-weight:600;color:#374151;">Offer Amount ($)</label>
                  <input
                    type="number"
                    name="amount"
                    placeholder="450000"
                    min="1"
                    required
                    style="width:100%;padding:0.5rem;border:1px solid #c4b5fd;border-radius:6px;margin-top:0.2rem;font-size:0.85rem;"
                  />
                </div>
                <div>
                  <label style="font-size:0.78rem;font-weight:600;color:#374151;">Message (optional)</label>
                  <textarea
                    name="message"
                    rows="2"
                    placeholder="I'm pre-approved..."
                    style="width:100%;padding:0.5rem;border:1px solid #c4b5fd;border-radius:6px;margin-top:0.2rem;font-size:0.85rem;"
                  ></textarea>
                </div>
                <button type="submit" class="btn btn-primary" style="background:#7c3aed;border-color:#7c3aed;font-size:0.85rem;">
                  Submit via Ash.create →
                </button>
              </form>
            </div>
          <% end %>

          <!-- Offers list -->
          <%= if @offers == [] do %>
            <div class="empty-state" style="padding:2rem 1rem;">
              <div class="empty-state-icon">📭</div>
              <div class="empty-state-title">No offers yet</div>
              <div class="empty-state-desc">
                <%= if is_buyer?(@current_user), do: "Submit an offer above.", else: "Buyers can submit offers on this property." %>
              </div>
            </div>
          <% else %>
            <div style="display:flex;flex-direction:column;gap:0.75rem;">
              <%= for offer <- @offers do %>
                <div class="offer-item">
                  <div class="offer-item-header">
                    <span class="offer-amount">$<%= offer.amount %></span>
                    <.badge color={offer_color(offer.status)}><%= offer.status %></.badge>
                  </div>
                  <%= if offer.buyer do %>
                    <div class="offer-buyer" style="font-size:0.75rem;color:#5b21b6;">
                      ⚡ via <code>belongs_to :buyer</code>: <%= offer.buyer.email %>
                    </div>
                  <% end %>
                  <%= if offer.message do %>
                    <div style="font-size:0.75rem;color:#64748b;font-style:italic;margin-top:0.2rem;">"<%= offer.message %>"</div>
                  <% end %>
                  <%= if owns?(@current_user, @property) && offer.status == "pending" do %>
                    <div class="offer-actions" style="margin-top:0.5rem;">
                      <button
                        phx-click="accept_offer"
                        phx-value-id={offer.id}
                        class="btn btn-sm"
                        style="background:#16a34a;color:white;border:none;padding:0.3rem 0.65rem;border-radius:5px;cursor:pointer;flex:1;font-size:0.75rem;"
                      >
                        ✓ Accept
                      </button>
                      <button
                        phx-click="reject_offer"
                        phx-value-id={offer.id}
                        class="btn btn-sm"
                        style="background:#dc2626;color:white;border:none;padding:0.3rem 0.65rem;border-radius:5px;cursor:pointer;flex:1;font-size:0.75rem;"
                      >
                        ✕ Reject
                      </button>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
