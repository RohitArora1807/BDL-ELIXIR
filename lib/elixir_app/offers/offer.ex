defmodule ElixirApp.Offers.Offer do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_statuses ~w(pending accepted rejected withdrawn)

  schema "offers" do
    field :amount,     :decimal
    field :status,     :string, default: "pending"
    field :message,    :string
    field :expires_at, :utc_datetime

    belongs_to :buyer,    ElixirApp.Accounts.User
    belongs_to :property, ElixirApp.Properties.Property

    timestamps(type: :utc_datetime)
  end

  def changeset(offer, attrs) do
    offer
    |> cast(attrs, [:buyer_id, :amount, :status, :message, :expires_at, :property_id])
    |> validate_required([:buyer_id, :amount, :property_id])
    |> validate_number(:amount, greater_than: 0)
    |> validate_inclusion(:status, @valid_statuses)
  end
end
