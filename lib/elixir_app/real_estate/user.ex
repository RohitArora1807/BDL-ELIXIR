defmodule ElixirApp.RealEstate.User do
  use Ash.Resource,
    domain: ElixirApp.RealEstate,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "users"
    repo ElixirApp.Repo
  end

  attributes do
    integer_primary_key :id
    attribute :email, :string, allow_nil?: false, public?: true
    attribute :name,  :string, public?: true
    attribute :role,  :string, default: "buyer",  public?: true
    timestamps()
  end

  relationships do
    has_many :properties, ElixirApp.RealEstate.Property,
      destination_attribute: :owner_id

    has_many :offers, ElixirApp.RealEstate.Offer,
      destination_attribute: :buyer_id

    has_many :favorites, ElixirApp.RealEstate.Favorite,
      destination_attribute: :user_id

    has_many :metric_events, ElixirApp.RealEstate.MetricEvent,
      destination_attribute: :user_id
  end

  actions do
    defaults [:read]
  end
end
