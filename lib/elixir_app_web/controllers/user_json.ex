defmodule ElixirAppWeb.UserJSON do
  alias ElixirApp.Accounts.User

  def show(%{user: user}), do: %{data: data(user)}

  def auth(%{user: user, token: token}), do: %{data: data(user), token: token}

  defp data(%User{} = u) do
    %{id: u.id, name: u.name, email: u.email, role: u.role}
  end
end
