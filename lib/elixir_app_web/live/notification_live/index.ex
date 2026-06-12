defmodule ElixirAppWeb.NotificationLive.Index do
  use ElixirAppWeb, :live_view

  alias ElixirApp.Notifications
  alias ElixirApp.Accounts

  @impl true
  def mount(_params, session, socket) do
    current_user  = load_user(session)
    notifications = if current_user, do: Notifications.list_for_user(current_user.id), else: []
    unread        = Enum.count(notifications, & !&1.read)

    if connected?(socket) && current_user do
      Phoenix.PubSub.subscribe(ElixirApp.PubSub, "notifications:#{current_user.id}")
    end

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:notifications, notifications)
     |> assign(:unread, unread)}
  end

  @impl true
  def handle_event("mark_all_read", _params, socket) do
    current_user = socket.assigns.current_user
    Notifications.mark_all_read(current_user.id)
    notifications = Notifications.list_for_user(current_user.id)

    {:noreply,
     socket
     |> assign(:notifications, notifications)
     |> assign(:unread, 0)}
  end

  @impl true
  def handle_info(%{event: _}, socket) do
    current_user  = socket.assigns.current_user
    notifications = Notifications.list_for_user(current_user.id)
    unread        = Enum.count(notifications, & !&1.read)
    {:noreply, assign(socket, notifications: notifications, unread: unread)}
  end

  defp load_user(%{"user_id" => user_id}), do: Accounts.get_user(user_id)
  defp load_user(_), do: nil

  defp notif_icon("new_offer"),      do: {"💬", "notif-icon notif-icon-yellow"}
  defp notif_icon("offer_accepted"), do: {"✅", "notif-icon notif-icon-green"}
  defp notif_icon("offer_rejected"), do: {"❌", "notif-icon notif-icon-red"}
  defp notif_icon(_),                do: {"🔔", "notif-icon notif-icon-gray"}

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="page-header">
        <div style="display:flex;align-items:center;gap:0.75rem;">
          <h1 class="page-title">Notifications</h1>
          <%= if @unread > 0 do %>
            <span class="unread-badge"><%= @unread %> new</span>
          <% end %>
        </div>
        <%= if @unread > 0 do %>
          <button phx-click="mark_all_read" class="btn btn-ghost btn-sm">
            ✓ Mark all as read
          </button>
        <% end %>
      </div>

      <div class="notif-list">
        <%= for notif <- @notifications do %>
          <% {icon, icon_cls} = notif_icon(notif.type) %>
          <div class={"notif-item #{if !notif.read, do: "unread", else: ""}"}>
            <div class={icon_cls}><%= icon %></div>
            <div class="notif-body">
              <div style="display:flex;align-items:center;gap:0.5rem;margin-bottom:0.25rem;">
                <span class="notif-title"><%= notif.title %></span>
                <%= if !notif.read do %>
                  <span class="unread-dot" title="Unread"></span>
                <% end %>
              </div>
              <div class="notif-text"><%= notif.body %></div>
            </div>
            <div class="notif-meta">
              <%= Calendar.strftime(notif.inserted_at, "%b %d, %Y") %>
            </div>
          </div>
        <% end %>

        <%= if @notifications == [] do %>
          <div class="empty-state">
            <div class="empty-state-icon">🔔</div>
            <div class="empty-state-title">All caught up</div>
            <div class="empty-state-desc">No notifications yet.</div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
