defmodule ElixirApp.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notifications" do
    field :type,     :string
    field :title,    :string
    field :body,     :string
    field :read,     :boolean, default: false
    field :metadata, :map,     default: %{}

    belongs_to :user, ElixirApp.Accounts.User

    timestamps()
  end

  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:user_id, :type, :title, :body, :read, :metadata])
    |> validate_required([:user_id, :type, :title, :body])
  end
end
