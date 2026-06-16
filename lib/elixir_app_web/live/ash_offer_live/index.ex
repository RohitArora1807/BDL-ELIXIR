defmodule ElixirAppWeb.AshOfferLive.Index do
  use ElixirAppWeb, :live_view

  import Ash.Query

  alias ElixirApp.RealEstate.{Offer, Property}
  alias ElixirApp.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user = load_user(session)
    offers       = list_offers(current_user)
    properties   = list_properties(current_user)

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:properties, properties)
     |> assign(:selected_property_id, nil)
     |> assign(:amount, "")
     |> assign(:message, "")
     |> assign(:show_form, false)
     |> stream(:offers, offers)}
  end

  @impl true
  def handle_params(_params, _url, socket), do: {:noreply, socket}

  # ── Toggle new offer form ────────────────────────────────────────────────

  @impl true
  def handle_event("toggle_form", _params, socket) do
    {:noreply, assign(socket, :show_form, !socket.assigns.show_form)}
  end

  # ── Submit new offer via Ash.create ─────────────────────────────────────
  # Teaching point: Ash.create automatically:
  #   1. Runs validations from the resource
  #   2. Checks the :create policy (buyer or admin only)
  #   3. Runs the change that sets buyer_id = actor.id
  #   4. Returns {:ok, offer} or {:error, changeset}

  def handle_event("submit_offer", %{"amount" => amount, "property_id" => property_id, "message" => message}, socket) do
    actor = socket.assigns.current_user

    case Ash.create(Offer, %{amount: amount, property_id: property_id, message: message},
           domain: ElixirApp.RealEstate,
           actor: actor
         ) do
      {:ok, offer} ->
        offers = list_offers(actor)
        {:noreply,
         socket
         |> put_flash(:info, "Offer submitted for $#{offer.amount}.")
         |> assign(:show_form, false)
         |> stream(:offers, offers, reset: true)}

      {:error, error} ->
        msg = if is_struct(error, Ash.Error.Forbidden),
          do: "Only buyers can submit offers.",
          else: "Invalid offer — check amount and property."
        {:noreply, put_flash(socket, :error, msg)}
    end
  end

  # ── Accept / Reject via named Ash actions ───────────────────────────────
  # Teaching point: :accept and :reject are named actions on the Offer resource.
  # They model real business workflows — not generic CRUD.
  # Calling Ash.update(offer, action: :accept) runs ONLY the accept action.

  def handle_event("accept", %{"id" => id}, socket) do
    run_decision(id, :accept, "accepted", socket)
  end

  def handle_event("reject", %{"id" => id}, socket) do
    run_decision(id, :reject, "rejected", socket)
  end

  defp run_decision(id, action, label, socket) do
    actor = socket.assigns.current_user

    with {:ok, offer} <- Ash.get(Offer, id, domain: ElixirApp.RealEstate, actor: actor),
         {:ok, _} <- Ash.update(offer, %{}, action: action, domain: ElixirApp.RealEstate, actor: actor) do
      offers = list_offers(actor)
      {:noreply,
       socket
       |> put_flash(:info, "Offer #{label}.")
       |> stream(:offers, offers, reset: true)}
    else
      {:error, %Ash.Error.Forbidden{}} ->
        {:noreply, put_flash(socket, :error, "Policy denied — not authorised.")}
      _ ->
        {:noreply, put_flash(socket, :error, "Action failed.")}
    end
  end

  # ── Private helpers ──────────────────────────────────────────────────────

  defp list_offers(nil), do: []
  defp list_offers(actor) do
    Offer
    |> Ash.read!(domain: ElixirApp.RealEstate, actor: actor, load: [:property, :buyer])
  end

  defp list_properties(nil), do: []
  defp list_properties(actor) do
    Property
    |> Ash.read!(domain: ElixirApp.RealEstate, actor: actor)
  end

  defp load_user(%{"user_id" => id}), do: Accounts.get_user(id)
  defp load_user(_), do: nil

  defp status_color("pending"),  do: "yellow"
  defp status_color("accepted"), do: "green"
  defp status_color("rejected"), do: "red"
  defp status_color(_),          do: "yellow"

  defp is_buyer?(nil),  do: false
  defp is_buyer?(user), do: user.role == "buyer"

  defp is_seller?(nil),  do: false
  defp is_seller?(user), do: user.role == "seller"

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <!-- Purple Ash banner -->
      <div style="background:linear-gradient(135deg,#7c3aed,#6d28d9);color:white;border-radius:12px;padding:1rem 1.5rem;margin-bottom:1.25rem;display:flex;justify-content:space-between;align-items:center;">
        <div>
          <div style="font-weight:700;">⚡ Ash Offers</div>
          <div style="font-size:0.75rem;opacity:0.85;">
            Demonstrates <code style="background:rgba(255,255,255,0.15);padding:0.1rem 0.3rem;border-radius:3px;">belongs_to</code> relationships + named actions <code style="background:rgba(255,255,255,0.15);padding:0.1rem 0.3rem;border-radius:3px;">:accept</code> / <code style="background:rgba(255,255,255,0.15);padding:0.1rem 0.3rem;border-radius:3px;">:reject</code>
          </div>
        </div>
        <.link navigate={~p"/app/offers"} style="color:white;opacity:0.75;font-size:0.8rem;">
          View Ecto version →
        </.link>
      </div>

      <div class="page-header">
        <h1 class="page-title" style="color:#7c3aed;">Offers (Ash)</h1>
        <%= if is_buyer?(@current_user) do %>
          <button phx-click="toggle_form" class="btn btn-primary" style="background:#7c3aed;border-color:#7c3aed;">
            <%= if @show_form, do: "Cancel", else: "+ New Offer" %>
          </button>
        <% end %>
      </div>

      <!-- Teaching note: relationships -->
      <div style="background:#f5f3ff;border:1px solid #ddd6fe;border-radius:10px;padding:1rem;margin-bottom:1.25rem;font-size:0.8rem;color:#5b21b6;">
        <strong>What Ash loads with <code>load: [:property, :buyer]</code>:</strong>
        Each offer below has its <code>property</code> and <code>buyer</code> fully loaded in one call.
        In Ecto you'd write: <code>Repo.preload(offer, [:property, :buyer])</code> manually.
        In Ash: <code>Ash.read!(Offer, load: [:property, :buyer])</code> — declared, not imperative.
      </div>

      <!-- New offer form -->
      <%= if @show_form do %>
        <div class="card card-pad" style="border-top:4px solid #7c3aed;margin-bottom:1.5rem;">
          <h3 style="font-size:0.95rem;font-weight:700;color:#7c3aed;margin-bottom:1rem;">Submit New Offer</h3>
          <form phx-submit="submit_offer" style="display:flex;flex-direction:column;gap:0.75rem;">
            <div>
              <label style="font-size:0.8rem;font-weight:600;color:#374151;">Property</label>
              <select name="property_id" style="width:100%;padding:0.5rem;border:1px solid #c4b5fd;border-radius:6px;margin-top:0.25rem;">
                <option value="">Select a property...</option>
                <%= for p <- @properties do %>
                  <option value={p.id}><%= p.title %> — $<%= p.price %></option>
                <% end %>
              </select>
            </div>
            <div>
              <label style="font-size:0.8rem;font-weight:600;color:#374151;">Offer Amount ($)</label>
              <input type="number" name="amount" placeholder="450000" style="width:100%;padding:0.5rem;border:1px solid #c4b5fd;border-radius:6px;margin-top:0.25rem;" />
            </div>
            <div>
              <label style="font-size:0.8rem;font-weight:600;color:#374151;">Message (optional)</label>
              <textarea name="message" rows="2" placeholder="I'm a pre-approved buyer..." style="width:100%;padding:0.5rem;border:1px solid #c4b5fd;border-radius:6px;margin-top:0.25rem;"></textarea>
            </div>
            <button type="submit" class="btn btn-primary" style="background:#7c3aed;border-color:#7c3aed;">
              Submit via Ash.create(Offer, ...)
            </button>
          </form>
        </div>
      <% end %>

      <!-- Offers list -->
      <div id="ash-offers-stream" phx-update="stream" style="display:flex;flex-direction:column;gap:1rem;">
        <%= for {dom_id, offer} <- @streams.offers do %>
          <div id={dom_id} class="card card-pad" style="border-left:4px solid #7c3aed;">
            <div style="display:flex;justify-content:space-between;align-items:flex-start;flex-wrap:wrap;gap:0.5rem;">
              <div>
                <div style="font-size:1rem;font-weight:700;color:#1e293b;">
                  $<%= offer.amount %>
                  <.badge color={status_color(offer.status)}><%= offer.status %></.badge>
                </div>
                <!-- Relationship: property loaded via belongs_to -->
                <%= if offer.property do %>
                  <div style="font-size:0.8rem;color:#7c3aed;margin-top:0.25rem;">
                    ⚡ Property (via <code>belongs_to :property</code>): <strong><%= offer.property.title %></strong>
                  </div>
                <% end %>
                <!-- Relationship: buyer loaded via belongs_to -->
                <%= if offer.buyer do %>
                  <div style="font-size:0.8rem;color:#6d28d9;margin-top:0.1rem;">
                    ⚡ Buyer (via <code>belongs_to :buyer</code>): <strong><%= offer.buyer.email %></strong>
                  </div>
                <% end %>
                <%= if offer.message do %>
                  <div style="font-size:0.8rem;color:#64748b;margin-top:0.4rem;font-style:italic;">"<%= offer.message %>"</div>
                <% end %>
              </div>

              <!-- Named actions: :accept and :reject -->
              <%= if is_seller?(@current_user) && offer.status == "pending" do %>
                <div style="display:flex;gap:0.5rem;">
                  <button
                    phx-click="accept"
                    phx-value-id={offer.id}
                    class="btn btn-sm"
                    style="background:#16a34a;color:white;border:none;padding:0.35rem 0.75rem;border-radius:6px;cursor:pointer;"
                  >
                    ✓ Accept (Ash :accept action)
                  </button>
                  <button
                    phx-click="reject"
                    phx-value-id={offer.id}
                    class="btn btn-sm"
                    style="background:#dc2626;color:white;border:none;padding:0.35rem 0.75rem;border-radius:6px;cursor:pointer;"
                  >
                    ✕ Reject (Ash :reject action)
                  </button>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>

      <%= if @streams.offers == %{} do %>
        <div class="empty-state">
          <div class="empty-state-icon">⚡</div>
          <div class="empty-state-title">No offers yet</div>
          <div class="empty-state-desc">Log in as a buyer to submit an offer via Ash.create</div>
        </div>
      <% end %>

      <!-- Code comparison -->
      <div style="margin-top:2rem;display:grid;grid-template-columns:1fr 1fr;gap:1rem;">
        <div style="background:#f0fdf4;border:1px solid #bbf7d0;border-radius:10px;padding:1rem;">
          <div style="font-size:0.75rem;font-weight:700;color:#15803d;margin-bottom:0.5rem;">ECTO — accept an offer</div>
          <pre style="font-size:0.7rem;color:#166534;white-space:pre-wrap;margin:0;">def accept_offer(offer, user) do
  if user.id == offer.property.owner_id do
    offer
    |> Offer.changeset(&#37;&#123;status: "accepted"&#125;)
    |> Repo.update()
  else
    &#123;:error, :unauthorized&#125;
  end
end</pre>
        </div>
        <div style="background:#f5f3ff;border:1px solid #ddd6fe;border-radius:10px;padding:1rem;">
          <div style="font-size:0.75rem;font-weight:700;color:#7c3aed;margin-bottom:0.5rem;">ASH — accept an offer</div>
          <pre style="font-size:0.7rem;color:#5b21b6;white-space:pre-wrap;margin:0;">Ash.update(offer,
  action: :accept,
  actor: current_user
)
# Policy + named action run automatically.
# No if/else. No manual auth check.</pre>
        </div>
      </div>
    </div>
    """
  end
end
