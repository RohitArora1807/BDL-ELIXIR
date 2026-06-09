defmodule ElixirAppWeb.UserSocket do
  use Phoenix.Socket
  require Logger

  # Every topic matching "notifications:*" is handled by this channel.
  # The "*" is a wildcard — one channel module can serve all user topics.
  channel "notifications:*", ElixirAppWeb.NotificationChannel

  # Called when the client first connects to the socket.
  # We verify the token here — before any channel can be joined.
  # If the token is bad, the whole connection is rejected.
  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case ElixirApp.Accounts.verify_token(token) do
      {:ok, user_id} ->
        user = ElixirApp.Accounts.get_user(user_id)
        if user do
          Logger.info("[UserSocket] connected user_id=#{user_id} email=#{user.email}")
          {:ok, assign(socket, :current_user, user)}
        else
          Logger.warning("[UserSocket] connect rejected — user_id=#{user_id} not found in DB")
          :error
        end

      _ ->
        Logger.warning("[UserSocket] connect rejected — bad token")
        :error
    end
  end

  # Reject connections that don't send a token
  def connect(_params, _socket, _connect_info), do: :error

  # Unique identifier for this socket connection — used by Phoenix
  # to allow targeted broadcasts to a specific user's sockets.
  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.current_user.id}"
end
