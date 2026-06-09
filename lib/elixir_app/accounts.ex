defmodule ElixirApp.Accounts do
  import Ecto.Query, warn: false
  alias ElixirApp.Repo
  alias ElixirApp.Accounts.User
  alias ElixirApp.Accounts.PasswordHasher

  def list_users do
    User |> order_by([u], u.inserted_at) |> Repo.all()
  end

  def get_user(id), do: Repo.get(User, id)

  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_email(email), do: Repo.get_by(User, email: email)

  def update_user_role(%User{} = user, attrs) do
    user |> User.role_changeset(attrs) |> Repo.update()
  end

  def register_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def authenticate_user(email, password) do
    user = get_user_by_email(email)

    cond do
      user && PasswordHasher.verify_pass(password, user.hashed_password) ->
        {:ok, user}

      user ->
        {:error, :invalid_credentials}

      true ->
        PasswordHasher.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  def generate_token(user) do
    Phoenix.Token.sign(ElixirAppWeb.Endpoint, "user auth", user.id)
  end

  def verify_token(token) do
    Phoenix.Token.verify(ElixirAppWeb.Endpoint, "user auth", token, max_age: 86_400 * 30)
  end
end
