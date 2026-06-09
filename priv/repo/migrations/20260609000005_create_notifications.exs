defmodule ElixirApp.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :user_id,  references(:users, on_delete: :delete_all), null: false
      add :type,     :string, null: false
      add :title,    :string, null: false
      add :body,     :string, null: false
      add :read,     :boolean, default: false, null: false
      add :metadata, :map, default: %{}

      timestamps()
    end

    create index(:notifications, [:user_id])
    create index(:notifications, [:user_id, :read])
  end
end
