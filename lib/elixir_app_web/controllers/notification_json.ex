defmodule ElixirAppWeb.NotificationJSON do
  def index(%{notifications: notifications}), do: %{data: Enum.map(notifications, &data/1)}

  defp data(n) do
    %{
      id:          n.id,
      type:        n.type,
      title:       n.title,
      body:        n.body,
      read:        n.read,
      metadata:    n.metadata,
      inserted_at: n.inserted_at
    }
  end
end
