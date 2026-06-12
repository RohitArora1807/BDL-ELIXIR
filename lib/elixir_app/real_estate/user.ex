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
    timestamps()
  end

  relationships do
    has_many :properties, ElixirApp.RealEstate.Property,
      destination_attribute: :owner_id
  end

  actions do
    defaults [:read]
  end
end
