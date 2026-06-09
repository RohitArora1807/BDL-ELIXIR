defmodule ElixirApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias ElixirApp.Accounts.PasswordHasher

  @valid_roles ~w(admin buyer seller buyer_seller)

  schema "users" do
    field :name,            :string
    field :email,           :string
    field :hashed_password, :string
    field :password,        :string, virtual: true
    field :role,            :string, default: "buyer"

    timestamps(type: :utc_datetime)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password, :role])
    |> validate_required([:email, :password])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> validate_length(:password, min: 6, message: "must be at least 6 characters")
    |> validate_inclusion(:role, @valid_roles, message: "must be buyer, seller, buyer_seller, or admin")
    |> unique_constraint(:email, message: "already registered")
    |> hash_password()
  end

  def role_changeset(user, attrs) do
    user
    |> cast(attrs, [:role])
    |> validate_required([:role])
    |> validate_inclusion(:role, @valid_roles, message: "must be buyer, seller, buyer_seller, or admin")
  end

  defp hash_password(%{valid?: true, changes: %{password: pw}} = changeset) do
    put_change(changeset, :hashed_password, PasswordHasher.hash_pwd_salt(pw))
  end
  defp hash_password(changeset), do: changeset
end
