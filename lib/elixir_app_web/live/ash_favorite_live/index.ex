defmodule ElixirAppWeb.AshFavoriteLive.Index do
  use ElixirAppWeb, :live_view

  alias ElixirApp.RealEstate.{Favorite, Property}
  alias ElixirApp.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user = load_user(session)
    favorites    = list_favorites(current_user)
    properties   = list_properties(current_user)

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:properties, properties)
     |> stream(:favorites, favorites)}
  end

  @impl true
  def handle_params(_params, _url, socket), do: {:noreply, socket}

  # ── Add favorite ─────────────────────────────────────────────────────────
  # Teaching point: Ash.create handles:
  #   1. Policy check (actor_present — any logged-in user)
  #   2. Sets user_id = actor.id automatically via change
  #   3. Unique identity prevents duplicates at DB level (unique_index)

  @impl true
  def handle_event("add_favorite", %{"property_id" => property_id}, socket) do
    actor = socket.assigns.current_user

    case Ash.create(Favorite, %{property_id: property_id},
           domain: ElixirApp.RealEstate,
           actor: actor
         ) do
      {:ok, _favorite} ->
        favorites = list_favorites(actor)
        {:noreply,
         socket
         |> put_flash(:info, "Added to favorites.")
         |> stream(:favorites, favorites, reset: true)}

      {:error, %Ash.Error.Forbidden{}} ->
        {:noreply, put_flash(socket, :error, "Must be logged in to favorite.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Already in favorites.")}
    end
  end

  # ── Remove favorite ───────────────────────────────────────────────────────
  # Teaching point: relates_to_actor_via(:user) in the destroy policy checks
  # favorite.user_id == actor.id automatically. No manual ownership check.

  def handle_event("remove_favorite", %{"id" => id}, socket) do
    actor = socket.assigns.current_user

    with {:ok, favorite} <- Ash.get(Favorite, id, domain: ElixirApp.RealEstate, actor: actor),
         :ok <- Ash.destroy(favorite, domain: ElixirApp.RealEstate, actor: actor) do
      favorites = list_favorites(actor)
      {:noreply,
       socket
       |> put_flash(:info, "Removed from favorites.")
       |> stream(:favorites, favorites, reset: true)}
    else
      {:error, %Ash.Error.Forbidden{}} ->
        {:noreply, put_flash(socket, :error, "Can only remove your own favorites.")}
      _ ->
        {:noreply, put_flash(socket, :error, "Remove failed.")}
    end
  end

  # ── Private helpers ──────────────────────────────────────────────────────

  defp list_favorites(nil), do: []
  defp list_favorites(actor) do
    import Ash.Query
    Favorite
    |> filter(user_id == ^actor.id)
    |> Ash.read!(domain: ElixirApp.RealEstate, actor: actor, load: [:property])
  end

  defp list_properties(nil), do: []
  defp list_properties(actor) do
    Property
    |> Ash.read!(domain: ElixirApp.RealEstate, actor: actor)
  end

  defp load_user(%{"user_id" => id}), do: Accounts.get_user(id)
  defp load_user(_), do: nil

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <!-- Purple Ash banner -->
      <div style="background:linear-gradient(135deg,#7c3aed,#6d28d9);color:white;border-radius:12px;padding:1rem 1.5rem;margin-bottom:1.25rem;display:flex;justify-content:space-between;align-items:center;">
        <div>
          <div style="font-weight:700;">⚡ Ash Favorites</div>
          <div style="font-size:0.75rem;opacity:0.85;">
            Demonstrates a <strong>join resource</strong> — User ↔ Property many-to-many via Favorite
          </div>
        </div>
        <.link navigate={~p"/app/ash"} style="color:white;opacity:0.75;font-size:0.8rem;">
          ← Ash Dashboard
        </.link>
      </div>

      <!-- Teaching note: join resource -->
      <div style="background:#f5f3ff;border:1px solid #ddd6fe;border-radius:10px;padding:1rem;margin-bottom:1.25rem;font-size:0.8rem;color:#5b21b6;">
        <strong>What is a join resource?</strong> A Favorite is a record that links a User to a Property.
        One user can have many favorites. One property can be favorited by many users.
        <br/>In Ecto: manual join table + preload queries. In Ash: <code>belongs_to :user</code> + <code>belongs_to :property</code>
        on one resource — Ash handles the rest.
        <br/>The <code>identities do</code> block creates a unique index: one user cannot favorite the same property twice.
      </div>

      <div class="page-header">
        <h1 class="page-title" style="color:#7c3aed;">My Favorites (Ash)</h1>
      </div>

      <!-- Add favorite form -->
      <div class="card card-pad" style="border-top:4px solid #7c3aed;margin-bottom:1.5rem;">
        <h3 style="font-size:0.9rem;font-weight:700;color:#7c3aed;margin-bottom:0.75rem;">
          Add a Favorite (calls Ash.create via <code>belongs_to</code>)
        </h3>
        <form phx-submit="add_favorite" style="display:flex;gap:0.75rem;align-items:flex-end;flex-wrap:wrap;">
          <div style="flex:1;min-width:200px;">
            <label style="font-size:0.8rem;font-weight:600;color:#374151;">Property</label>
            <select name="property_id" style="width:100%;padding:0.5rem;border:1px solid #c4b5fd;border-radius:6px;margin-top:0.25rem;">
              <option value="">Select a property...</option>
              <%= for p <- @properties do %>
                <option value={p.id}><%= p.title %></option>
              <% end %>
            </select>
          </div>
          <button type="submit" class="btn btn-primary" style="background:#7c3aed;border-color:#7c3aed;">
            ♥ Add Favorite
          </button>
        </form>
      </div>

      <!-- Favorites list -->
      <div id="ash-favorites-stream" phx-update="stream" style="display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:1rem;">
        <%= for {dom_id, fav} <- @streams.favorites do %>
          <div id={dom_id} class="card" style="border-top:3px solid #7c3aed;">
            <div class="prop-body">
              <%= if fav.property do %>
                <div style="font-size:0.7rem;font-weight:700;color:#7c3aed;margin-bottom:0.3rem;">
                  ⚡ via <code>belongs_to :property</code>
                </div>
                <div style="font-weight:700;color:#1e293b;margin-bottom:0.25rem;"><%= fav.property.title %></div>
                <div style="font-size:0.8rem;color:#64748b;margin-bottom:0.25rem;">📍 <%= fav.property.location %></div>
                <div style="font-weight:700;color:#7c3aed;margin-bottom:0.75rem;">$<%= fav.property.price %></div>
              <% else %>
                <div style="color:#94a3b8;font-size:0.85rem;">Property not loaded</div>
              <% end %>
              <button
                phx-click="remove_favorite"
                phx-value-id={fav.id}
                style="background:#fef2f2;color:#dc2626;border:1px solid #fecaca;border-radius:6px;padding:0.3rem 0.75rem;font-size:0.75rem;cursor:pointer;width:100%;"
              >
                ✕ Remove (Ash.destroy — policy checks ownership)
              </button>
            </div>
          </div>
        <% end %>
      </div>

      <%= if @streams.favorites == %{} do %>
        <div class="empty-state">
          <div class="empty-state-icon">♥</div>
          <div class="empty-state-title">No favorites yet</div>
          <div class="empty-state-desc">Add a property above — Ash sets user_id automatically from actor</div>
        </div>
      <% end %>

      <!-- Code comparison -->
      <div style="margin-top:2rem;display:grid;grid-template-columns:1fr 1fr;gap:1rem;">
        <div style="background:#f0fdf4;border:1px solid #bbf7d0;border-radius:10px;padding:1rem;">
          <div style="font-size:0.75rem;font-weight:700;color:#15803d;margin-bottom:0.5rem;">ECTO — add a favorite</div>
          <pre style="font-size:0.7rem;color:#166534;white-space:pre-wrap;margin:0;">%Favorite&#123;&#125;
|> Favorite.changeset(&#37;&#123;
     user_id: current_user.id,
     property_id: property_id
   &#125;)
|> Repo.insert()
# unique_index error if duplicate</pre>
        </div>
        <div style="background:#f5f3ff;border:1px solid #ddd6fe;border-radius:10px;padding:1rem;">
          <div style="font-size:0.75rem;font-weight:700;color:#7c3aed;margin-bottom:0.5rem;">ASH — add a favorite</div>
          <pre style="font-size:0.7rem;color:#5b21b6;white-space:pre-wrap;margin:0;">Ash.create(Favorite,
  &#37;&#123;property_id: property_id&#125;,
  actor: current_user
)
# user_id set automatically.
# identity prevents duplicates.</pre>
        </div>
      </div>
    </div>
    """
  end
end
