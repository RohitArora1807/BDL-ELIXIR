defmodule ElixirAppWeb.NotificationChannel do
  use Phoenix.Channel
  require Logger

  # Called when a client does: channel.join("notifications:42")
  # The "42" is matched from the topic string.
  # We compare it to the authenticated user's ID — you can only
  # subscribe to YOUR OWN topic, not someone else's.
  @impl true
  def join("notifications:" <> user_id_str, _params, socket) do
    requesting_id = socket.assigns.current_user.id

    if String.to_integer(user_id_str) == requesting_id do
      Logger.info("[NotificationChannel] user #{requesting_id} joined notifications:#{user_id_str}")
      {:ok, socket}
    else
      Logger.warning("[NotificationChannel] user #{requesting_id} tried to join notifications:#{user_id_str} — rejected")
      {:error, %{reason: "unauthorized"}}
    end
  end

  # No handle_in needed — this channel is push-only (server → client).
  # Clients never send messages here, they just listen.
end
