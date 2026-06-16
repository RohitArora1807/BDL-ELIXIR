defmodule ElixirAppWeb.AshMetricLive.Index do
  use ElixirAppWeb, :live_view

  alias ElixirApp.RealEstate.{MetricEvent, Property}
  alias ElixirApp.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user = load_user(session)
    events       = list_events(current_user)

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:properties, list_properties(current_user))
     |> assign(:selected_event, "property_viewed")
     |> stream(:events, events)}
  end

  @impl true
  def handle_params(_params, _url, socket), do: {:noreply, socket}

  # ── Log a metric event ───────────────────────────────────────────────────
  # Teaching point: Ash.create with action: :log
  # The :log action is append-only — no :update or :destroy action defined.
  # Calling Ash.update on a MetricEvent returns Ash.Error.Forbidden.

  @impl true
  def handle_event("log_event", %{"event_type" => event_type, "property_id" => property_id}, socket) do
    actor = socket.assigns.current_user

    property_id = if property_id == "", do: nil, else: property_id

    case Ash.create(MetricEvent, %{event_type: event_type, property_id: property_id},
           action: :log,
           domain: ElixirApp.RealEstate,
           actor: actor
         ) do
      {:ok, _event} ->
        events = list_events(actor)
        {:noreply,
         socket
         |> put_flash(:info, "Event \"#{event_type}\" logged.")
         |> stream(:events, events, reset: true)}

      {:error, %Ash.Error.Forbidden{}} ->
        {:noreply, put_flash(socket, :error, "Must be logged in to log events.")}

      {:error, error} ->
        msg = inspect(error)
        {:noreply, put_flash(socket, :error, "Validation failed: #{msg}")}
    end
  end

  defp list_events(nil), do: []
  defp list_events(actor) do
    case Ash.read(MetricEvent, domain: ElixirApp.RealEstate, actor: actor, load: [:property]) do
      {:ok, events} -> events
      _             -> []
    end
  end

  defp list_properties(nil), do: []
  defp list_properties(actor) do
    Property |> Ash.read!(domain: ElixirApp.RealEstate, actor: actor)
  end

  defp load_user(%{"user_id" => id}), do: Accounts.get_user(id)
  defp load_user(_), do: nil

  defp is_admin?(nil),  do: false
  defp is_admin?(user), do: user.role == "admin"

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <!-- Purple Ash banner -->
      <div style="background:linear-gradient(135deg,#7c3aed,#6d28d9);color:white;border-radius:12px;padding:1rem 1.5rem;margin-bottom:1.25rem;display:flex;justify-content:space-between;align-items:center;">
        <div>
          <div style="font-weight:700;">⚡ Ash MetricEvents</div>
          <div style="font-size:0.75rem;opacity:0.85;">
            Demonstrates an <strong>append-only resource</strong> — no update, no delete, ever.
          </div>
        </div>
        <.link navigate={~p"/app/ash/comparison"} style="color:white;opacity:0.75;font-size:0.8rem;">
          View comparison →
        </.link>
      </div>

      <!-- Teaching note -->
      <div style="background:#fff7ed;border:1px solid #fed7aa;border-radius:10px;padding:1rem;margin-bottom:1.25rem;font-size:0.8rem;color:#9a3412;">
        <strong>Append-only pattern:</strong> MetricEvent has no <code>update</code> policy and no <code>destroy</code> policy.
        This means calling <code>Ash.update(event, ...)</code> or <code>Ash.destroy(event, ...)</code> returns
        <code>Ash.Error.Forbidden</code> automatically — enforced at the <strong>authorization layer</strong>, not just by convention.
        This guarantees the event log can never be tampered with.
      </div>

      <div style="display:grid;grid-template-columns:1fr 1fr;gap:1.5rem;">

        <!-- Left: log an event -->
        <div>
          <div class="card card-pad" style="border-top:4px solid #7c3aed;">
            <h3 style="font-size:0.9rem;font-weight:700;color:#7c3aed;margin-bottom:1rem;">
              Log an Event (Ash.create action: :log)
            </h3>
            <form phx-submit="log_event" style="display:flex;flex-direction:column;gap:0.75rem;">
              <div>
                <label style="font-size:0.8rem;font-weight:600;color:#374151;">Event Type</label>
                <select name="event_type" style="width:100%;padding:0.5rem;border:1px solid #c4b5fd;border-radius:6px;margin-top:0.25rem;">
                  <option value="property_viewed">property_viewed</option>
                  <option value="property_searched">property_searched</option>
                  <option value="offer_submitted">offer_submitted</option>
                  <option value="offer_accepted">offer_accepted</option>
                  <option value="offer_rejected">offer_rejected</option>
                  <option value="favorite_added">favorite_added</option>
                  <option value="favorite_removed">favorite_removed</option>
                  <option value="page_viewed">page_viewed</option>
                </select>
              </div>
              <div>
                <label style="font-size:0.8rem;font-weight:600;color:#374151;">Property (optional)</label>
                <select name="property_id" style="width:100%;padding:0.5rem;border:1px solid #c4b5fd;border-radius:6px;margin-top:0.25rem;">
                  <option value="">None</option>
                  <%= for p <- @properties do %>
                    <option value={p.id}><%= p.title %></option>
                  <% end %>
                </select>
              </div>
              <button type="submit" class="btn btn-primary" style="background:#7c3aed;border-color:#7c3aed;">
                Log Event
              </button>
            </form>
          </div>

          <!-- Append-only proof -->
          <div style="background:#fef2f2;border:1px solid #fecaca;border-radius:10px;padding:1rem;margin-top:1rem;font-size:0.8rem;color:#991b1b;">
            <strong>Try updating an event (blocked):</strong>
            <br/>No update form exists here intentionally.
            If you tried <code>Ash.update(event, %{}, actor: user)</code> in IEx,
            you would get <code>%Ash.Error.Forbidden{}</code> — not a runtime error, a policy denial.
          </div>
        </div>

        <!-- Right: event log -->
        <div>
          <h3 style="font-size:0.9rem;font-weight:700;color:#1e293b;margin-bottom:0.75rem;">
            Event Log
            <%= if is_admin?(@current_user) do %>
              <span style="font-size:0.7rem;background:#7c3aed;color:white;padding:0.15rem 0.5rem;border-radius:999px;margin-left:0.5rem;">admin view</span>
            <% else %>
              <span style="font-size:0.7rem;background:#f59e0b;color:white;padding:0.15rem 0.5rem;border-radius:999px;margin-left:0.5rem;">admin only</span>
            <% end %>
          </h3>

          <div id="ash-metrics-stream" phx-update="stream" style="display:flex;flex-direction:column;gap:0.6rem;max-height:420px;overflow-y:auto;">
            <%= for {dom_id, event} <- @streams.events do %>
              <div id={dom_id} style="background:#faf5ff;border:1px solid #ddd6fe;border-radius:8px;padding:0.6rem 0.9rem;">
                <div style="display:flex;justify-content:space-between;align-items:center;">
                  <code style="font-size:0.75rem;color:#7c3aed;font-weight:600;"><%= event.event_type %></code>
                  <span style="font-size:0.65rem;color:#94a3b8;"><%= Calendar.strftime(event.inserted_at, "%H:%M:%S") %></span>
                </div>
                <%= if event.property do %>
                  <div style="font-size:0.72rem;color:#6d28d9;margin-top:0.2rem;">
                    📍 <%= event.property.title %>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>

          <%= if @streams.events == %{} do %>
            <div style="text-align:center;padding:2rem;color:#94a3b8;font-size:0.85rem;">
              <%= if is_admin?(@current_user) do %>
                No events logged yet.
              <% else %>
                Only admins can read the event log.
                Log some events — they are being stored even if you cannot see them here.
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
