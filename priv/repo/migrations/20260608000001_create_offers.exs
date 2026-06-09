defmodule ElixirApp.Repo.Migrations.CreateOffers do
  use Ecto.Migration

  def change do
    create table(:offers) do
      add :buyer_id,    :integer,  null: false
      add :amount,      :decimal,  null: false, precision: 15, scale: 2
      add :status,      :string,   null: false, default: "pending"
      add :message,     :text
      add :expires_at,  :utc_datetime
      add :property_id, references(:properties, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:offers, [:property_id])
    create index(:offers, [:buyer_id])
    create index(:offers, [:status])
  end
end
