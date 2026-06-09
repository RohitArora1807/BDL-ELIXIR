defmodule ElixirAppWeb.NotificationController do
  use ElixirAppWeb, :controller

  alias ElixirApp.Notifications

  action_fallback ElixirAppWeb.FallbackController

  # GET /api/notifications — return all notifications for current user
  def index(conn, _params) do
    notifications = Notifications.list_for_user(conn.assigns.current_user.id)
    render(conn, :index, notifications: notifications)
  end

  # PUT /api/notifications/mark_read — mark all as read
  # Called when the user opens the bell panel
  def mark_read(conn, _params) do
    Notifications.mark_all_read(conn.assigns.current_user.id)
    send_resp(conn, :no_content, "")
  end

  # DELETE /api/notifications — delete only unread (New) notifications
  def clear(conn, _params) do
    Notifications.clear_unread(conn.assigns.current_user.id)
    send_resp(conn, :no_content, "")
  end
end
