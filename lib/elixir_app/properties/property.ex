defmodule ElixirApp.Properties.Property do
  use Ecto.Schema
  import Ecto.Changeset

  schema "properties" do
    field :title,       :string
    field :description, :string
    field :price,       :decimal
    field :location,    :string
    field :bedrooms,    :integer
    field :bathrooms,   :integer
    field :area,        :float
    field :type,        :string
    field :status,      :string
    field :image_path,  :string

    belongs_to :owner, ElixirApp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(property, attrs) do
    property
    |> cast(attrs, [:title, :description, :price, :location, :bedrooms, :bathrooms, :area, :type, :status, :owner_id, :image_path])
    |> validate_required([:title, :price, :location])
    |> validate_length(:title, min: 3, max: 100)
    |> validate_number(:price, greater_than: 0)
  end
end
