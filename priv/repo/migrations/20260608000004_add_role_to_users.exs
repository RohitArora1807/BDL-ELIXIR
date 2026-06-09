defmodule ElixirApp.Repo.Migrations.AddRoleToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :role, :string, default: "buyer", null: false
    end

    create index(:users, [:role])
  end
end
