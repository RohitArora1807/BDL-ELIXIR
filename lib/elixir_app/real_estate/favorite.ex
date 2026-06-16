defmodule ElixirApp.RealEstate.Favorite do
  use Ash.Resource,
    domain: ElixirApp.RealEstate,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "ash_favorites"
    repo ElixirApp.Repo
  end

  # Teaching point: identities enforce uniqueness at the DB level.
  # One user can only favorite the same property once.
  # Ash generates a unique_index migration from this automatically.

  identities do
    identity :unique_user_property, [:user_id, :property_id]
  end

  # ── Attributes ────────────────────────────────────────────────────────────

  attributes do
    uuid_primary_key :id
    timestamps()
  end

  # ── Relationships ──────────────────────────────────────────────────────────
  # Teaching point: Favorite is a JOIN resource (User ↔ Property many-to-many).
  # In Ecto you'd write this join table manually.
  # In Ash, belongs_to handles both the FK column AND the relationship loading.
  #
  # This means: Ash.read!(Favorite, load: [:property, :user]) loads BOTH
  # related records in a single call — no manual preload needed.

  relationships do
    belongs_to :property, ElixirApp.RealEstate.Property,
      attribute_type: :uuid,
      public?: true

    belongs_to :user, ElixirApp.RealEstate.User,
      attribute_type: :integer,
      public?: true
  end

  # ── Policies ──────────────────────────────────────────────────────────────

  policies do
    # Anyone can read favorites.
    policy action_type(:read) do
      authorize_if always()
    end

    # Any logged-in user can favorite a property.
    policy action_type(:create) do
      authorize_if actor_present()
    end

    # Only the user who favorited (or admin) can remove it.
    # relates_to_actor_via(:user) checks: favorite.user_id == actor.id
    policy action_type(:destroy) do
      authorize_if actor_attribute_equals(:role, "admin")
      authorize_if relates_to_actor_via(:user)
    end
  end

  # ── Actions ───────────────────────────────────────────────────────────────

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:property_id]

      # Auto-set user_id from actor.
      change fn changeset, context ->
        case context.actor do
          %{id: id} -> Ash.Changeset.force_change_attribute(changeset, :user_id, id)
          _         -> changeset
        end
      end
    end

    # Read favorites for a specific user, with property preloaded.
    read :for_user do
      argument :user_id, :integer, allow_nil?: false
      filter expr(user_id == ^arg(:user_id))
    end
  end
end
