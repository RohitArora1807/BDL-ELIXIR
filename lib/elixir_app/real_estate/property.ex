defmodule ElixirApp.RealEstate.Property do
  use Ash.Resource,
    domain: ElixirApp.RealEstate,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "ash_properties"
    repo ElixirApp.Repo
  end

  # ── Attributes ────────────────────────────────────────────────────────────
  # Like Ecto schema fields, but Ash owns the type coercion and nil checks.

  attributes do
    uuid_primary_key :id

    attribute :title,       :string,  allow_nil?: false, public?: true
    attribute :description, :string,  public?: true
    attribute :location,    :string,  allow_nil?: false, public?: true
    attribute :price,       :decimal, allow_nil?: false, public?: true
    attribute :bedrooms,    :integer, public?: true
    attribute :bathrooms,   :integer, public?: true
    attribute :area,        :float,   public?: true
    attribute :type,        :string,  default: "house",      public?: true
    attribute :status,      :string,  default: "available",  public?: true
    attribute :image_path,  :string,  public?: true

    timestamps()
  end

  # ── Relationships ──────────────────────────────────────────────────────────
  # belongs_to creates the owner_id foreign key column automatically.
  # has_many on User points back here.
  # No migration needed — owner_id column already exists from our first migration.

  relationships do
    belongs_to :owner, ElixirApp.RealEstate.User,
      attribute_type: :integer,
      public?: true
  end

  # ── Validations ───────────────────────────────────────────────────────────
  # Declared in the resource — not in a changeset function like Ecto.
  # Runs automatically on every matching action.

  validations do
    validate present(:title)
    validate present(:location)
    validate present(:price)
    validate numericality(:price, greater_than: 0)
    validate string_length(:title, min: 3, max: 100)
  end

  # ── Actions ───────────────────────────────────────────────────────────────
  # Actions replace context module functions.
  # :read and :destroy use Ash defaults.
  # :create and :update are customized with accepted fields and changes.

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:title, :description, :location, :price,
              :bedrooms, :bathrooms, :area, :type, :image_path, :owner_id]

      # Changes run as part of the action pipeline — like before_save callbacks.
      # This one forces status to "available" on every new listing.
      change set_attribute(:status, "available")
    end

    update :update do
      accept [:title, :description, :location, :price,
              :bedrooms, :bathrooms, :area, :type, :status, :image_path]

      # Change: record when the price was last changed
      change set_attribute(:updated_at, &DateTime.utc_now/0)
    end

    # Custom read — filter by status
    read :available do
      filter expr(status == "available")
    end

    # Custom read — filter by owner
    read :by_owner do
      argument :owner_id, :integer, allow_nil?: false
      filter expr(owner_id == ^arg(:owner_id))
    end
  end
end
