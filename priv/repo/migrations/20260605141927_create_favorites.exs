defmodule ElixirApp.Repo.Migrations.CreateFavorites do
  use Ecto.Migration

  def change do
    create table(:favorites) do
      add :user_id,     :integer, null: false
      add :property_id, references(:properties, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:favorites, [:user_id, :property_id])
    create index(:favorites, [:user_id])
  end
end
