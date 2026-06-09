defmodule ElixirApp.Notifications do
  import Ecto.Query, warn: false
  alias ElixirApp.Repo
  alias ElixirApp.Notifications.Notification

  # Persist a notification row. Called before every broadcast so
  # offline users get it when they next load the page.
  def create(attrs) do
    %Notification{} |> Notification.changeset(attrs) |> Repo.insert()
  end

  # Fetch the 50 most recent notifications for a user (read + unread).
  def list_for_user(user_id) do
    Notification
    |> where([n], n.user_id == ^user_id)
    |> order_by([n], desc: n.inserted_at)
    |> limit(50)
    |> Repo.all()
  end

  # Mark every unread notification as read for a user.
  # Called when the user opens the bell panel.
  def mark_all_read(user_id) do
    Notification
    |> where([n], n.user_id == ^user_id and n.read == false)
    |> Repo.update_all(set: [read: true])
  end

  # Delete only unread notifications for a user.
  # "Clear All" dismisses new alerts without destroying history.
  def clear_unread(user_id) do
    Notification
    |> where([n], n.user_id == ^user_id and n.read == false)
    |> Repo.delete_all()
  end
end
