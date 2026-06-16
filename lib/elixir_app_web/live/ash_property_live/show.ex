defmodule ElixirAppWeb.AshPropertyLive.Show do
  use ElixirAppWeb, :live_view

  alias ElixirApp.RealEstate.Property
  alias ElixirApp.Accounts

  @impl true
  def mount(_params, session, socket) do
    {:ok, assign(socket, :current_user, load_user(session))}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    actor = socket.assigns.current_user

    # ── Ash way ───────────────────────────────────────────────────────────
    # Ash.get! loads one record by primary key and runs policies.
    # load: [:owner] asks Ash to preload the owner relationship automatically.
    #
    # Ecto equivalent:
    #   Properties.get_property!(id)  →  Repo.get!(Property, id) |> Repo.preload(:owner)
    #
    # Key difference: Ash checks the :read policy before hitting the DB.
    # If the policy denies access, it raises Ash.Error.Forbidden — not a 404.
    case Ash.get(Property, id, domain: ElixirApp.RealEstate, actor: actor, load: [:owner]) do
      {:ok, nil} ->
        {:noreply,
         socket
         |> put_flash(:error, "Property not found.")
         |> push_navigate(to: ~p"/app/ash/properties")}

      {:ok, property} ->
        {:noreply,
         socket
         |> assign(:property, property)
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

  # ── Delete via Ash ───────────────────────────────────────────────────────
  # Ecto way:
  #   assert_owner(socket)   # manual check — did you forget this? = bug
  #   Properties.delete_property(property)
  #
  # Ash way:
  #   Ash.destroy!(property, actor: actor)
  #   The :destroy policy runs automatically — if role != admin → forbidden.
  #   No assert_owner needed. You cannot forget the check.

  @impl true
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

  defp load_user(%{"user_id" => id}), do: Accounts.get_user(id)
  defp load_user(_), do: nil

  defp owns?(nil, _),      do: false
  defp owns?(user, prop),  do: user.id == prop.owner_id

  defp is_admin?(nil),     do: false
  defp is_admin?(user),    do: user.role == "admin"

  defp status_color("available"), do: "green"
  defp status_color("sold"),      do: "red"
  defp status_color(_),           do: "yellow"

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

        <!-- Right: Ash vs Ecto comparison -->
        <div class="card card-pad">
          <h2 style="font-size:0.95rem;font-weight:700;color:#1e293b;margin-bottom:1rem;">
            What's different here vs Ecto?
          </h2>

          <div style="display:flex;flex-direction:column;gap:1rem;">

            <div style="background:#f0fdf4;border-radius:8px;padding:0.9rem;">
              <div style="font-size:0.7rem;font-weight:700;color:#15803d;margin-bottom:0.4rem;">ECTO show.ex does:</div>
              <pre style="font-size:0.7rem;color:#166534;white-space:pre-wrap;margin:0;">property = Properties.get_property!(id)
# Then manually:
defp assert_owner(socket) do
  if user.id == property.owner_id,
    do: :ok,
    else: &#123;:error, :unauthorized&#125;
end
# Forget assert_owner = security bug</pre>
            </div>

            <div style="background:#f5f3ff;border-radius:8px;padding:0.9rem;">
              <div style="font-size:0.7rem;font-weight:700;color:#7c3aed;margin-bottom:0.4rem;">ASH show.ex does:</div>
              <pre style="font-size:0.7rem;color:#5b21b6;white-space:pre-wrap;margin:0;">Ash.get(Property, id, actor: user)
# Policy runs automatically before DB hit.
# No assert_owner. Can't forget it.
# Ash.destroy(property, actor: user)
# Policy checked again — admin only.</pre>
            </div>

            <div style="background:#fff7ed;border:1px solid #fed7aa;border-radius:8px;padding:0.9rem;">
              <div style="font-size:0.75rem;font-weight:700;color:#c2410c;margin-bottom:0.4rem;">Key insight:</div>
              <div style="font-size:0.75rem;color:#9a3412;line-height:1.6;">
                In Ecto, authorization is in your LiveView code — easy to miss. In Ash, authorization lives in the resource's <code>policies do</code> block and runs on every call automatically.
              </div>
            </div>

          </div>
        </div>
      </div>
    </div>
    """
  end
end
