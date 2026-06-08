defmodule ElixirApp.Repo.Migrations.CreateProperties do
  use Ecto.Migration

  def change do
    create table(:properties) do
      add :title, :string
      add :description, :text
      add :price, :decimal
      add :location, :string
      add :bedrooms, :integer
      add :bathrooms, :integer
      add :area, :float
      add :type, :string
      add :status, :string

      timestamps(type: :utc_datetime)
    end
  end
end
