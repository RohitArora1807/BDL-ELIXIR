defmodule ElixirAppWeb.LiveHooks do
  import Phoenix.LiveView
  import Phoenix.Component

  alias ElixirApp.Notifications
  alias ElixirApp.Accounts

  def on_mount(:notifications, _params, session, socket) do
    current_user = load_user(session)
    unread = unread_count(current_user)

    socket =
      socket
      |> assign(:nav_unread, unread)
      |> attach_hook(:nav_notifications, :handle_info, fn
        # A new notification arrived — increment the dot
        %{event: _}, socket ->
          {:halt, update(socket, :nav_unread, &(&1 + 1))}

        # Unrelated message — let the LiveView handle it normally
        _msg, socket ->
          {:cont, socket}
      end)

    if connected?(socket) && current_user do
      Phoenix.PubSub.subscribe(ElixirApp.PubSub, "notifications:#{current_user.id}")
    end

    {:cont, socket}
  end

  defp load_user(%{"user_id" => id}), do: Accounts.get_user(id)
  defp load_user(_), do: nil

  defp unread_count(nil), do: 0
  defp unread_count(user) do
    Notifications.list_for_user(user.id)
    |> Enum.count(& !&1.read)
  end
end
