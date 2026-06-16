defmodule ElixirAppWeb.AshPropertyLive.Index do
  use ElixirAppWeb, :live_view

  alias ElixirApp.RealEstate.Property
  alias ElixirApp.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user = load_user(session)
    properties   = list_properties("", "all", current_user)

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:search, "")
     |> assign(:filter_status, "all")
     |> assign(:empty, properties == [])
     |> stream(:properties, properties)}
  end

  @impl true
  def handle_params(_params, _url, socket), do: {:noreply, socket}

  # ── Search ──────────────────────────────────────────────────────────────
  # Ecto way: Properties.list_properties_filtered(query, status)
  #   → calls ilike() inside an Ecto.Query where clause
  #
  # Ash way: Ash.Query.filter with contains() — Ash translates this to
  #   ilike in SQL for AshPostgres. Same result, declared differently.

  @impl true
  def handle_event("search", %{"search" => query}, socket) do
    properties = list_properties(query, socket.assigns.filter_status, socket.assigns.current_user)
    {:noreply,
     socket
     |> assign(:search, query)
     |> assign(:empty, properties == [])
     |> stream(:properties, properties, reset: true)}
  end

  def handle_event("filter", %{"status" => status}, socket) do
    properties = list_properties(socket.assigns.search, status, socket.assigns.current_user)
    {:noreply,
     socket
     |> assign(:filter_status, status)
     |> assign(:empty, properties == [])
     |> stream(:properties, properties, reset: true)}
  end

  # ── Private: build the Ash query ────────────────────────────────────────

  defp list_properties(search, status, actor) do
    import Ash.Query

    # Ecto equivalent:
    #   from p in Property,
    #     where: ilike(p.title, ^term),
    #     where: p.status == ^status,
    #     preload: [:owner]
    #
    # Ash builds a query struct, then Ash.read! executes it.
    # The actor: option means policy checks run before the DB is hit.

    Property
    |> then(fn q ->
      if search && search != "" do
        filter(q, contains(title, ^search) or contains(location, ^search))
      else
        q
      end
    end)
    |> then(fn q ->
      if status && status != "all" do
        filter(q, status == ^status)
      else
        q
      end
    end)
    |> Ash.read!(domain: ElixirApp.RealEstate, actor: actor, load: [:owner])
  end

  defp load_user(%{"user_id" => id}), do: Accounts.get_user(id)
  defp load_user(_), do: nil

  defp status_color("available"), do: "green"
  defp status_color("sold"),      do: "red"
  defp status_color(_),           do: "yellow"

  defp can_create?(nil),  do: false
  defp can_create?(user), do: user.role in ["seller", "admin"]

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <!-- Ash header banner -->
      <div style="background:linear-gradient(135deg,#7c3aed,#6d28d9);color:white;border-radius:12px;padding:1rem 1.5rem;margin-bottom:1.25rem;display:flex;justify-content:space-between;align-items:center;">
        <div>
          <div style="font-weight:700;">⚡ Ash Properties</div>
          <div style="font-size:0.75rem;opacity:0.85;">
            Queries use <code style="background:rgba(255,255,255,0.15);padding:0.1rem 0.3rem;border-radius:3px;">Ash.Query.filter</code> + <code style="background:rgba(255,255,255,0.15);padding:0.1rem 0.3rem;border-radius:3px;">Ash.read!</code>
          </div>
        </div>
        <.link navigate={~p"/app/properties"} style="color:white;opacity:0.75;font-size:0.8rem;">
          View Ecto version →
        </.link>
      </div>

      <!-- Page header -->
      <div class="page-header">
        <h1 class="page-title" style="color:#7c3aed;">Properties (Ash)</h1>
        <%= if can_create?(@current_user) do %>
          <.link navigate={~p"/app/ash/properties/new"} class="btn btn-primary" style="background:#7c3aed;border-color:#7c3aed;">
            + List via Ash
          </.link>
        <% end %>
      </div>

      <!-- Search + filter -->
      <div class="search-row">
        <input
          type="text"
          placeholder="Search title or location..."
          value={@search}
          phx-keyup="search"
          name="search"
          class="search-input"
          style="border-color:#c4b5fd;"
        />
        <select phx-change="filter" name="status" class="filter-select" style="border-color:#c4b5fd;">
          <option value="all">All Status</option>
          <option value="available">Available</option>
          <option value="sold">Sold</option>
          <option value="pending">Pending</option>
        </select>
      </div>

      <!-- Properties grid -->
      <div id="ash-properties-stream" phx-update="stream" class="properties-grid">
        <%= for {dom_id, property} <- @streams.properties do %>
          <div id={dom_id} class="prop-card" style="border-top:3px solid #7c3aed;">
            <div class={"prop-thumb"} style="background:linear-gradient(135deg,#f5f3ff,#ede9fe);font-size:2rem;display:flex;align-items:center;justify-content:center;min-height:120px;">
              <%= if property.type == "house", do: "🏠", else: "🏢" %>
            </div>
            <div class="prop-body">
              <div class="prop-title-row">
                <h3 class="prop-title"><%= property.title %></h3>
                <.badge color={status_color(property.status)}><%= property.status %></.badge>
              </div>
              <div class="prop-location">📍 <%= property.location %></div>
              <%= if property.owner do %>
                <div class="prop-owner" style="color:#7c3aed;">
                  ⚡ Loaded via Ash: <%= property.owner.email %>
                </div>
              <% end %>
              <div class="prop-price">$<%= property.price %></div>
              <div class="prop-meta">
                <span>🛏 <%= property.bedrooms %></span>
                <span>🚿 <%= property.bathrooms %></span>
                <span>📐 <%= property.area %> sqft</span>
              </div>
            </div>
            <div class="prop-footer">
              <.link navigate={~p"/app/ash/properties/#{property.id}"} class="btn btn-primary btn-sm" style="background:#7c3aed;border-color:#7c3aed;">
                View (Ash) →
              </.link>
            </div>
          </div>
        <% end %>
      </div>

      <%= if @empty do %>
        <div class="empty-state">
          <div class="empty-state-icon">⚡</div>
          <div class="empty-state-title">No Ash properties found</div>
          <div class="empty-state-desc">
            These live in the <code>ash_properties</code> table — separate from the Ecto <code>properties</code> table.
          </div>
          <%= if can_create?(@current_user) do %>
            <.link navigate={~p"/app/ash/properties/new"} class="btn btn-primary" style="margin-top:1rem;background:#7c3aed;">
              Create your first Ash property
            </.link>
          <% end %>
        </div>
      <% end %>

      <!-- Code comparison -->
      <div style="margin-top:2rem;display:grid;grid-template-columns:1fr 1fr;gap:1rem;">
        <div style="background:#f0fdf4;border:1px solid #bbf7d0;border-radius:10px;padding:1rem;">
          <div style="font-size:0.75rem;font-weight:700;color:#15803d;margin-bottom:0.5rem;">ECTO (properties.ex)</div>
          <pre style="font-size:0.7rem;color:#166534;white-space:pre-wrap;margin:0;">def list_properties_filtered(search, status) do
  Property
  |> filter_search(search)
  |> filter_status_query(status)
  |> preload(:owner)
  |> Repo.all()
end</pre>
        </div>
        <div style="background:#f5f3ff;border:1px solid #ddd6fe;border-radius:10px;padding:1rem;">
          <div style="font-size:0.75rem;font-weight:700;color:#7c3aed;margin-bottom:0.5rem;">ASH (this LiveView)</div>
          <pre style="font-size:0.7rem;color:#5b21b6;white-space:pre-wrap;margin:0;">Property
|> filter(contains(title, ^search))
|> filter(status == ^status)
|> Ash.read!(
     domain: ElixirApp.RealEstate,
     actor: current_user,
     load: [:owner]
   )</pre>
        </div>
      </div>
    </div>
    """
  end
end
