defmodule ElixirAppWeb.AdminJSON do
  alias ElixirApp.Accounts.User

  def index(%{users: users}), do: %{data: Enum.map(users, &data/1)}

  def show(%{user: user}), do: %{data: data(user)}

  defp data(%User{} = u) do
    %{
      id:          u.id,
      name:        u.name,
      email:       u.email,
      role:        u.role,
      inserted_at: u.inserted_at
    }
  end
end
