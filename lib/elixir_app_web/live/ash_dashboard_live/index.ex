defmodule ElixirAppWeb.AshDashboardLive.Index do
  use ElixirAppWeb, :live_view

  alias ElixirApp.RealEstate.Property
  alias ElixirApp.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user = load_user(session)
    actor        = current_user

    # ── Ash way ───────────────────────────────────────────────────────────
    # Ash.read! calls the default :read action on Property.
    # The actor is passed so policies are enforced (read allows everyone).
    # Returns a list of Ash resource structs, not Ecto schemas.
    #
    # Ecto equivalent:
    #   Repo.all(from p in Property, preload: [:owner])
    properties = Ash.read!(Property, domain: ElixirApp.RealEstate, actor: actor, load: [:owner])

    stats = %{
      total:     length(properties),
      available: Enum.count(properties, &(&1.status == "available")),
      sold:      Enum.count(properties, &(&1.status == "sold")),
      pending:   Enum.count(properties, &(&1.status == "pending"))
    }

    recent = properties |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime}) |> Enum.take(4)

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:stats, stats)
     |> assign(:recent, recent)}
  end

  defp load_user(%{"user_id" => id}), do: Accounts.get_user(id)
  defp load_user(_), do: nil

  defp status_color("available"), do: "#16a34a"
  defp status_color("sold"),      do: "#dc2626"
  defp status_color(_),           do: "#d97706"

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <!-- Ash banner -->
      <div style="background:linear-gradient(135deg,#7c3aed,#6d28d9);color:white;border-radius:12px;padding:1.25rem 1.5rem;margin-bottom:1.5rem;display:flex;justify-content:space-between;align-items:center;">
        <div>
          <div style="font-size:1.1rem;font-weight:700;">⚡ Ash Dashboard</div>
          <div style="font-size:0.8rem;opacity:0.85;margin-top:0.2rem;">
            Data fetched with <code style="background:rgba(255,255,255,0.15);padding:0.1rem 0.35rem;border-radius:4px;">Ash.read!(Property, actor: current_user)</code>
          </div>
        </div>
        <.link navigate={~p"/app/dashboard"} style="color:white;opacity:0.75;font-size:0.8rem;">
          View Ecto version →
        </.link>
      </div>

      <!-- Stats -->
      <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:1rem;margin-bottom:1.5rem;">
        <%= for {label, value, color} <- [
          {"Total (Ash)", @stats.total, "#7c3aed"},
          {"Available",  @stats.available, "#16a34a"},
          {"Sold",       @stats.sold, "#dc2626"},
          {"Pending",    @stats.pending, "#d97706"}
        ] do %>
          <div style="background:white;border:1px solid #e2e8f0;border-radius:12px;padding:1rem 1.25rem;border-top:3px solid #{color};">
            <div style="font-size:1.75rem;font-weight:800;color:#{color};"><%= value %></div>
            <div style="font-size:0.8rem;color:#64748b;margin-top:0.2rem;"><%= label %></div>
          </div>
        <% end %>
      </div>

      <!-- Recent properties -->
      <div style="background:white;border:1px solid #e2e8f0;border-radius:12px;padding:1.25rem;">
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:1rem;">
          <h2 style="font-size:1rem;font-weight:700;color:#1e293b;">Recent Listings (via Ash)</h2>
          <.link navigate={~p"/app/ash/properties"} style="font-size:0.8rem;color:#7c3aed;font-weight:600;">
            See all →
          </.link>
        </div>

        <!-- Ash code hint -->
        <div style="background:#f5f3ff;border:1px solid #ddd6fe;border-radius:8px;padding:0.6rem 0.9rem;margin-bottom:1rem;font-family:monospace;font-size:0.75rem;color:#5b21b6;">
          Ash.read!(Property, domain: ElixirApp.RealEstate, actor: current_user, load: [:owner])
        </div>

        <%= if @recent == [] do %>
          <div style="text-align:center;padding:2rem;color:#94a3b8;">
            <div style="font-size:2rem;">🏠</div>
            <div style="margin-top:0.5rem;">No Ash properties yet.</div>
            <.link navigate={~p"/app/ash/properties/new"} style="color:#7c3aed;font-weight:600;font-size:0.875rem;">
              Create one with the Ash form →
            </.link>
          </div>
        <% else %>
          <div style="display:flex;flex-direction:column;gap:0.75rem;">
            <%= for property <- @recent do %>
              <div style="display:flex;justify-content:space-between;align-items:center;padding:0.75rem;background:#faf5ff;border-radius:8px;border:1px solid #ede9fe;">
                <div>
                  <div style="font-weight:600;color:#1e293b;font-size:0.9rem;"><%= property.title %></div>
                  <div style="font-size:0.75rem;color:#7c3aed;">📍 <%= property.location %></div>
                </div>
                <div style="display:flex;align-items:center;gap:0.75rem;">
                  <div style="font-weight:700;color:#1e293b;">$<%= property.price %></div>
                  <span style={"background:#{status_color(property.status)}22;color:#{status_color(property.status)};font-size:0.7rem;font-weight:600;padding:0.2rem 0.5rem;border-radius:999px;"}>
                    <%= property.status %>
                  </span>
                  <.link navigate={~p"/app/ash/properties/#{property.id}"} style="font-size:0.75rem;color:#7c3aed;font-weight:600;">
                    View →
                  </.link>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <!-- Comparison note -->
      <div style="margin-top:1.5rem;display:grid;grid-template-columns:1fr 1fr;gap:1rem;">
        <div style="background:#f0fdf4;border:1px solid #bbf7d0;border-radius:12px;padding:1rem;">
          <div style="font-weight:700;color:#15803d;margin-bottom:0.5rem;">Ecto Dashboard does:</div>
          <div style="font-family:monospace;font-size:0.75rem;color:#166534;line-height:2;">
            Properties.stats() → custom SQL<br/>
            Properties.list_recent_properties(5)<br/>
            Repo.all(query) |> manual preloads<br/>
            No auth check in query
          </div>
        </div>
        <div style="background:#f5f3ff;border:1px solid #ddd6fe;border-radius:12px;padding:1rem;">
          <div style="font-weight:700;color:#7c3aed;margin-bottom:0.5rem;">Ash Dashboard does:</div>
          <div style="font-family:monospace;font-size:0.75rem;color:#5b21b6;line-height:2;">
            Ash.read!(Property, actor: user)<br/>
            load: [:owner] → automatic preload<br/>
            Enum.count() in Elixir for stats<br/>
            Policy check runs automatically
          </div>
        </div>
      </div>
    </div>
    """
  end
end
