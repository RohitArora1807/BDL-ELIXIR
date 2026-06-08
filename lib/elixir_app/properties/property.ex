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

    timestamps(type: :utc_datetime)
  end

  def changeset(property, attrs) do
    property
    |> cast(attrs, [:title, :description, :price, :location, :bedrooms, :bathrooms, :area, :type, :status])
    |> validate_required([:title, :price, :location, :status])
  end
end
