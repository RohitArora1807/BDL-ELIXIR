defmodule ElixirApp.RealEstate.MetricEvent do
  use Ash.Resource,
    domain: ElixirApp.RealEstate,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "ash_metric_events"
    repo ElixirApp.Repo
  end

  # ── Attributes ────────────────────────────────────────────────────────────
  # Teaching point: :map type stores arbitrary JSON — perfect for event metadata.
  # Examples: %{search_term: "sydney"}, %{price_viewed: 500000}, %{bid_amount: 300000}

  attributes do
    uuid_primary_key :id

    attribute :event_type, :string, allow_nil?: false, public?: true
    attribute :metadata,   :map,    default: %{},     public?: true

    timestamps()
  end

  # ── Relationships ──────────────────────────────────────────────────────────

  relationships do
    belongs_to :user, ElixirApp.RealEstate.User,
      attribute_type: :integer,
      public?: true

    # property_id is optional — some events are not property-specific
    belongs_to :property, ElixirApp.RealEstate.Property,
      attribute_type: :uuid,
      allow_nil?: true,
      public?: true
  end

  # ── Policies ──────────────────────────────────────────────────────────────
  # Teaching point: APPEND-ONLY resource.
  # There is intentionally NO update policy and NO destroy policy.
  # Ash will deny update and destroy calls automatically — no code needed.
  # This pattern is used for audit logs, event sourcing, analytics.

  policies do
    # Only admins can read the full event log.
    policy action_type(:read) do
      authorize_if actor_attribute_equals(:role, "admin")
    end

    # Any logged-in user can log an event (page views, bids attempted, etc.)
    policy action_type(:create) do
      authorize_if actor_present()
    end

    # No :update policy → all update calls forbidden automatically.
    # No :destroy policy → all destroy calls forbidden automatically.
    # This enforces append-only at the authorization layer — not just by convention.
  end

  # ── Validations ───────────────────────────────────────────────────────────

  validations do
    validate present(:event_type)
    validate string_length(:event_type, min: 2, max: 50)
    validate one_of(:event_type, [
      "property_viewed",
      "property_searched",
      "offer_submitted",
      "offer_accepted",
      "offer_rejected",
      "favorite_added",
      "favorite_removed",
      "page_viewed"
    ])
  end

  # ── Actions ───────────────────────────────────────────────────────────────
  # Teaching point: only :read and :log — no :update or :destroy defined.
  # Calling Ash.update or Ash.destroy on a MetricEvent will return
  # {:error, %Ash.Error.Forbidden{}} — enforced by policy, not by convention.

  actions do
    defaults [:read]

    create :log do
      accept [:event_type, :metadata, :property_id]

      change fn changeset, context ->
        case context.actor do
          %{id: id} -> Ash.Changeset.force_change_attribute(changeset, :user_id, id)
          _         -> changeset
        end
      end
    end

    # Admin reads events for a specific property.
    read :for_property do
      argument :property_id, :uuid, allow_nil?: false
      filter expr(property_id == ^arg(:property_id))
    end

    # Admin reads events for a specific user.
    read :for_user do
      argument :user_id, :integer, allow_nil?: false
      filter expr(user_id == ^arg(:user_id))
    end
  end
end
