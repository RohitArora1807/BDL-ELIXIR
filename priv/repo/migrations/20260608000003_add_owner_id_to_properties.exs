defmodule ElixirApp.Repo.Migrations.AddOwnerIdToProperties do
  use Ecto.Migration

  def change do
    alter table(:properties) do
      add :owner_id, references(:users, on_delete: :nilify_all)
    end

    create index(:properties, [:owner_id])
  end
end
