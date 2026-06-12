defmodule ElixirAppWeb.PropertyLive.Index do
  use ElixirAppWeb, :live_view

  alias ElixirApp.Properties
  alias ElixirApp.Properties.Property
  alias ElixirApp.Favorites
  alias ElixirApp.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user = load_user(session)
    properties   = Properties.list_properties()
    stats        = Properties.stats()

    favorite_ids =
      if current_user do
        Favorites.list_favorites(current_user.id)
        |> Enum.map(& &1.property_id)
        |> MapSet.new()
      else
        MapSet.new()
      end

    if connected?(socket), do: Phoenix.PubSub.subscribe(ElixirApp.PubSub, "properties")

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:favorite_ids, favorite_ids)
     |> assign(:stats, stats)
     |> assign(:search, "")
     |> assign(:filter_status, "all")
     |> assign(:empty, properties == [])
     |> assign(:pubsub_log, [])
     |> assign(:show_new_form, false)
     |> assign(:form, to_form(Property.changeset(%Property{}, %{"type" => "house", "status" => "available"})))
     |> allow_upload(:image, accept: ~w(.jpg .jpeg .png .webp), max_entries: 1, max_file_size: 5_000_000)
     |> stream(:properties, properties)}
  end

  @impl true
  def handle_params(%{} = _params, _url, socket) do
    show = socket.assigns.live_action == :new

    socket =
      if show,
        do: socket,
        else: assign(socket, :form, to_form(Property.changeset(%Property{}, %{"type" => "house", "status" => "available"})))

    {:noreply, assign(socket, :show_new_form, show)}
  end

  @impl true
  def handle_event("search", %{"search" => query}, socket) do
    properties = Properties.list_properties_filtered(query, socket.assigns.filter_status)
    {:noreply,
     socket
     |> assign(:search, query)
     |> assign(:empty, properties == [])
     |> stream(:properties, properties, reset: true)}
  end

  def handle_event("filter", %{"status" => status}, socket) do
    properties = Properties.list_properties_filtered(socket.assigns.search, status)
    {:noreply,
     socket
     |> assign(:filter_status, status)
     |> assign(:empty, properties == [])
     |> stream(:properties, properties, reset: true)}
  end

  def handle_event("toggle_favorite", %{"id" => property_id}, socket) do
    current_user = socket.assigns.current_user
    property_id  = String.to_integer(property_id)
    favorite_ids = socket.assigns.favorite_ids

    if MapSet.member?(favorite_ids, property_id) do
      fav = Favorites.list_favorites(current_user.id) |> Enum.find(&(&1.property_id == property_id))
      if fav, do: Favorites.remove_favorite(fav)
      {:noreply, assign(socket, :favorite_ids, MapSet.delete(favorite_ids, property_id))}
    else
      Favorites.add_favorite(%{user_id: current_user.id, property_id: property_id})
      {:noreply, assign(socket, :favorite_ids, MapSet.put(favorite_ids, property_id))}
    end
  end

  def handle_event("cancel_new", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/app/properties")}
  end

  def handle_event("validate", %{"property" => params}, socket) do
    changeset =
      %Property{}
      |> Property.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"property" => params}, socket) do
    current_user = socket.assigns.current_user

    image_path =
      consume_uploaded_entries(socket, :image, fn %{path: tmp_path}, entry ->
        ext      = Path.extname(entry.client_name)
        filename = "#{System.unique_integer([:positive])}#{ext}"
        dest     = Path.join(Application.app_dir(:elixir_app, "priv/static/uploads"), filename)
        File.cp!(tmp_path, dest)
        {:ok, "/uploads/#{filename}"}
      end)
      |> List.first()

    attrs =
      params
      |> Map.put("owner_id", current_user.id)
      |> Map.put("image_path", image_path)

    case Properties.create_property(attrs) do
      {:ok, _property} ->
        # stream_insert happens via handle_info({:property_created, ...}) from PubSub broadcast
        {:noreply,
         socket
         |> assign(:stats, Properties.stats())
         |> assign(:form, to_form(Property.changeset(%Property{}, %{"type" => "house", "status" => "available"})))
         |> push_patch(to: ~p"/app/properties")
         |> put_flash(:info, "Property listed successfully!")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  @impl true
  def handle_info({:property_created, property}, socket) do
    log = "[#{Time.utc_now() |> Time.truncate(:second)}] ✅ Received: \"#{property.title}\" was just listed"
    {:noreply,
     socket
     |> stream_insert(:properties, property, at: 0)
     |> assign(:empty, false)
     |> assign(:stats, Properties.stats())
     |> update(:pubsub_log, fn logs -> [log | logs] end)}
  end

  # --- Auth helpers ---

  defp load_user(%{"user_id" => user_id}), do: Accounts.get_user(user_id)
  defp load_user(_), do: nil

  defp can_list_property?(nil), do: false
  defp can_list_property?(user), do: user.role in ["seller", "buyer_seller", "admin"]

  # --- Color helpers ---

  defp status_color("available"), do: "green"
  defp status_color("sold"),      do: "red"
  defp status_color("rented"),    do: "yellow"
  defp status_color(_),           do: "gray"

  defp error_to_string(:too_large),      do: "File too large (max 5MB)"
  defp error_to_string(:not_accepted),   do: "Only .jpg, .jpeg, .png, .webp allowed"
  defp error_to_string(:too_many_files), do: "Upload 1 image at a time"
  defp error_to_string(err),             do: inspect(err)

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%!-- Stats Row --%>
      <div class="stats-row">
        <.stat_card label="Total"     value={@stats.total}     color="#4f46e5" />
        <.stat_card label="Available" value={@stats.available} color="#16a34a" />
        <.stat_card label="Sold"      value={@stats.sold}      color="#dc2626" />
        <.stat_card label="Rented"    value={@stats.rented}    color="#d97706" />
      </div>

      <%!-- Header --%>
      <div class="page-header">
        <h1 class="page-title">Properties</h1>
        <%= if can_list_property?(@current_user) do %>
          <.link patch={~p"/app/properties/new"} class="btn btn-primary">
            + List a Property
          </.link>
        <% end %>
      </div>

      <%!-- New Property Modal --%>
      <%= if @show_new_form do %>
        <div class="modal-overlay">
          <div class="modal">
            <div class="modal-header">
              <h2 class="modal-title">List a Property</h2>
              <button phx-click="cancel_new" class="modal-close">✕</button>
            </div>
            <div class="modal-body">
              <.form for={@form} phx-change="validate" phx-submit="save">
                <div class="form-grid">
                  <div class="form-row-full">
                    <.input field={@form[:title]} label="Title *" placeholder="e.g. Modern 3BR House" required />
                  </div>
                  <div class="form-row-full">
                    <.input field={@form[:location]} label="Location *" placeholder="e.g. Morgantown, WV" required />
                  </div>
                  <div>
                    <.input field={@form[:price]} type="number" label="Price ($) *" min="1" placeholder="350000" required />
                  </div>
                  <div>
                    <label class="form-label">Type</label>
                    <select name={@form[:type].name} id={@form[:type].id} class="form-input">
                      <option value="house"     selected={@form[:type].value == "house"}>House</option>
                      <option value="apartment" selected={@form[:type].value == "apartment"}>Apartment</option>
                    </select>
                  </div>
                  <div>
                    <.input field={@form[:bedrooms]} type="number" label="Bedrooms" min="0" placeholder="3" />
                  </div>
                  <div>
                    <.input field={@form[:bathrooms]} type="number" label="Bathrooms" min="0" placeholder="2" />
                  </div>
                  <div>
                    <.input field={@form[:area]} type="number" label="Area (sqft)" min="0" step="0.1" placeholder="1500" />
                  </div>
                  <div>
                    <label class="form-label">Status</label>
                    <select name={@form[:status].name} id={@form[:status].id} class="form-input">
                      <option value="available" selected={@form[:status].value == "available"}>Available</option>
                      <option value="rented"    selected={@form[:status].value == "rented"}>Rented</option>
                      <option value="sold"      selected={@form[:status].value == "sold"}>Sold</option>
                    </select>
                  </div>
                  <div class="form-row-full">
                    <.input field={@form[:description]} type="textarea" label="Description" placeholder="Describe the property..." />
                  </div>
                  <div class="form-row-full">
                    <label class="form-label">Property Image</label>
                    <.live_file_input upload={@uploads.image} class="upload-input" />
                    <%= for entry <- @uploads.image.entries do %>
                      <div class="upload-preview">
                        <.live_img_preview entry={entry} class="upload-thumb" />
                        <span class="upload-name"><%= entry.client_name %></span>
                        <button type="button" phx-click="cancel_upload" phx-value-ref={entry.ref} class="btn btn-ghost btn-sm">✕</button>
                      </div>
                    <% end %>
                    <%= for err <- upload_errors(@uploads.image) do %>
                      <span class="field-error"><%= error_to_string(err) %></span>
                    <% end %>
                  </div>
                </div>
                <div class="form-actions">
                  <button type="submit" class="btn btn-primary btn-block">List Property</button>
                  <button type="button" phx-click="cancel_new" class="btn btn-ghost">Cancel</button>
                </div>
              </.form>
            </div>
          </div>
        </div>
      <% end %>

      <%!-- PubSub live log --%>
      <%= if @pubsub_log != [] do %>
        <div style="background:#0f172a;border-radius:8px;padding:1rem 1.25rem;margin-bottom:1.5rem;font-family:monospace;">
          <div style="font-size:0.7rem;color:#64748b;margin-bottom:0.5rem;text-transform:uppercase;letter-spacing:0.08em;">PubSub — live updates received by this tab</div>
          <%= for entry <- @pubsub_log do %>
            <div style="font-size:0.8rem;color:#4ade80;padding:0.2rem 0;"><%= entry %></div>
          <% end %>
        </div>
      <% end %>

      <%!-- Search + Filter --%>
      <div class="search-row">
        <input
          type="text"
          placeholder="Search by title or location..."
          value={@search}
          phx-keyup="search"
          name="search"
          class="search-input"
        />
        <select phx-change="filter" name="status" class="filter-select">
          <option value="all">All Status</option>
          <option value="available">Available</option>
          <option value="sold">Sold</option>
          <option value="rented">Rented</option>
        </select>
      </div>

      <%!-- Properties Grid — phx-update="stream" tells LiveView to patch individual items --%>
      <div id="properties-stream" phx-update="stream" class="properties-grid">
        <%= for {dom_id, property} <- @streams.properties do %>
          <div id={dom_id} class="prop-card">
            <%= if property.image_path do %>
              <img src={property.image_path} alt={property.title} class="prop-card-img" />
            <% else %>
              <div class={"prop-thumb #{if property.type == "house", do: "prop-thumb-house", else: "prop-thumb-apt"}"}>
                <%= if property.type == "house", do: "🏠", else: "🏢" %>
              </div>
            <% end %>
            <div class="prop-body">
              <div class="prop-title-row">
                <h3 class="prop-title"><%= property.title %></h3>
                <div class="prop-title-actions">
                  <.badge color={status_color(property.status)}><%= property.status %></.badge>
                  <button
                    phx-click="toggle_favorite"
                    phx-value-id={property.id}
                    class="fav-btn"
                    title={if MapSet.member?(@favorite_ids, property.id), do: "Remove favorite", else: "Add favorite"}
                  >
                    <%= if MapSet.member?(@favorite_ids, property.id), do: "❤️", else: "🤍" %>
                  </button>
                </div>
              </div>
              <div class="prop-location">📍 <%= property.location %></div>
              <%= if property.owner do %>
                <div class="prop-owner">Listed by <%= property.owner.name || property.owner.email %></div>
              <% end %>
              <div class="prop-price">$<%= property.price %></div>
              <div class="prop-meta">
                <span>🛏 <%= property.bedrooms %> bed</span>
                <span>🚿 <%= property.bathrooms %> bath</span>
                <span>📐 <%= property.area %> sqft</span>
              </div>
            </div>
            <div class="prop-footer">
              <.link navigate={~p"/app/properties/#{property.id}"} class="btn btn-primary btn-sm">
                View Details →
              </.link>
            </div>
          </div>
        <% end %>
      </div>

      <%= if @empty do %>
        <div class="empty-state">
          <div class="empty-state-icon">🔍</div>
          <div class="empty-state-title">No properties found</div>
          <div class="empty-state-desc">Try adjusting your search or filter.</div>
        </div>
      <% end %>
    </div>
    """
  end
end
