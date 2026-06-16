defmodule ElixirApp.RealEstate.Property do
  use Ash.Resource,
    domain: ElixirApp.RealEstate,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

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

  # ── Policies ──────────────────────────────────────────────────────────────
  # Policies are checked on every Ash call. The actor (logged-in user) is
  # compared against each rule. If no rule passes → Ash.Error.Forbidden.
  #
  # authorize_if  → allow IF the check passes
  # forbid_if     → deny  IF the check passes
  # Rules are evaluated top-to-bottom; first match wins per policy block.

  policies do
    # Everyone can read — buyers browse listings.
    policy action_type(:read) do
      authorize_if always()
    end

    # Admins can create anything. Sellers can list their own properties.
    # Buyers cannot create. No actor → forbidden.
    policy action_type(:create) do
      authorize_if actor_attribute_equals(:role, "admin")
      authorize_if actor_attribute_equals(:role, "seller")
    end

    # Admins can update any property.
    # Sellers can only update properties they own (checked via :owner relationship).
    policy action_type(:update) do
      authorize_if actor_attribute_equals(:role, "admin")
      authorize_if [actor_attribute_equals(:role, "seller"), relates_to_actor_via(:owner)]
    end

    # Only admins can delete.
    policy action_type(:destroy) do
      authorize_if actor_attribute_equals(:role, "admin")
    end
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
              :bedrooms, :bathrooms, :area, :type, :image_path]

      # Automatically set the owner to whoever is making the request.
      # context.actor is whatever you passed as actor: in the Ash call.
      change fn changeset, context ->
        case context.actor do
          %{id: id} -> Ash.Changeset.force_change_attribute(changeset, :owner_id, id)
          _         -> changeset
        end
      end

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
