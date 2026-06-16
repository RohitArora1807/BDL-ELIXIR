defmodule ElixirApp.RealEstate.Offer do
  use Ash.Resource,
    domain: ElixirApp.RealEstate,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "ash_offers"
    repo ElixirApp.Repo
  end

  # ── Attributes ────────────────────────────────────────────────────────────
  # Teaching point: Ash owns type coercion. :decimal for money, never :float.

  attributes do
    uuid_primary_key :id

    attribute :amount,  :decimal, allow_nil?: false, public?: true
    attribute :status,  :string,  default: "pending", public?: true
    attribute :message, :string,  public?: true

    timestamps()
  end

  # ── Relationships ──────────────────────────────────────────────────────────
  # Teaching point: belongs_to creates the FK column automatically.
  # load: [:property, :buyer] in Ash.read! loads both in one call.
  #
  # Property uses uuid_primary_key → attribute_type: :uuid
  # User    uses integer_primary_key → attribute_type: :integer

  relationships do
    belongs_to :property, ElixirApp.RealEstate.Property,
      attribute_type: :uuid,
      public?: true

    belongs_to :buyer, ElixirApp.RealEstate.User,
      attribute_type: :integer,
      public?: true
  end

  # ── Policies ──────────────────────────────────────────────────────────────
  # Teaching point: policies declared ONCE here — not scattered across controllers.
  # Every Ash.read!, Ash.create, Ash.update call runs these automatically.

  policies do
    # Anyone can read offers (seller sees offers on their property).
    policy action_type(:read) do
      authorize_if always()
    end

    # Only buyers and admins can submit offers.
    policy action_type(:create) do
      authorize_if actor_attribute_equals(:role, "buyer")
      authorize_if actor_attribute_equals(:role, "admin")
    end

    # Only the buyer who made the offer (or admin) can update it.
    # relates_to_actor_via(:buyer) checks: offer.buyer_id == actor.id
    policy action_type(:update) do
      authorize_if actor_attribute_equals(:role, "admin")
      authorize_if relates_to_actor_via(:buyer)
    end

    # Admin only can hard-delete.
    policy action_type(:destroy) do
      authorize_if actor_attribute_equals(:role, "admin")
    end
  end

  # ── Validations ───────────────────────────────────────────────────────────
  # Teaching point: validations live in the Resource, not in a changeset function.
  # Run automatically on every create and update.

  validations do
    validate present(:amount)
    validate numericality(:amount, greater_than: 0)
    validate present(:property_id)
    validate one_of(:status, ["pending", "accepted", "rejected"])
  end

  # ── Actions ───────────────────────────────────────────────────────────────
  # Teaching point: actions replace context module functions.
  # :accept and :reject are NAMED actions — they model real business workflows,
  # not just generic CRUD. This is where Ash differs most from plain Ecto.

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:amount, :message, :property_id]

      # Auto-set buyer_id from whoever is making the call.
      change fn changeset, context ->
        case context.actor do
          %{id: id} -> Ash.Changeset.force_change_attribute(changeset, :buyer_id, id)
          _         -> changeset
        end
      end

      change set_attribute(:status, "pending")
    end

    # Seller accepts an offer — named action models the real workflow.
    update :accept do
      accept []
      change set_attribute(:status, "accepted")
    end

    # Seller rejects an offer.
    update :reject do
      accept []
      change set_attribute(:status, "rejected")
    end

    # Read my offers — filter by buyer_id.
    read :by_buyer do
      argument :buyer_id, :integer, allow_nil?: false
      filter expr(buyer_id == ^arg(:buyer_id))
    end

    # Read all offers on a property.
    read :for_property do
      argument :property_id, :uuid, allow_nil?: false
      filter expr(property_id == ^arg(:property_id))
    end
  end
end
