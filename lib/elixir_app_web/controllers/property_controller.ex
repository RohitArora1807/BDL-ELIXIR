defmodule ElixirAppWeb.PropertyController do
  use ElixirAppWeb, :controller

  alias ElixirApp.Properties
  alias ElixirApp.Properties.Property

  action_fallback ElixirAppWeb.FallbackController

  def index(conn, _params) do
    properties = Properties.list_properties()
    render(conn, :index, properties: properties)
  end

  def show(conn, %{"id" => id}) do
    property = Properties.get_property!(id)
    render(conn, :show, property: property)
  end

  def create(conn, %{"property" => params}) do
    user = conn.assigns.current_user

    with :ok <- can_list_property?(user) do
      params = Map.put(params, "owner_id", user.id)

      with {:ok, %Property{} = property} <- Properties.create_property(params) do
        property = ElixirApp.Repo.preload(property, :owner)

        conn
        |> put_status(:created)
        |> put_resp_header("location", ~p"/api/properties/#{property}")
        |> render(:show, property: property)
      end
    end
  end

  def update(conn, %{"id" => id, "property" => params}) do
    property = Properties.get_property!(id)

    with :ok <- authorize_owner(property, conn.assigns.current_user),
         {:ok, %Property{} = property} <- Properties.update_property(property, params) do
      render(conn, :show, property: property)
    end
  end

  def delete(conn, %{"id" => id}) do
    property = Properties.get_property!(id)

    with :ok <- authorize_owner(property, conn.assigns.current_user),
         {:ok, %Property{}} <- Properties.delete_property(property) do
      send_resp(conn, :no_content, "")
    end
  end

  defp can_list_property?(%{role: r}) when r in ~w(seller buyer_seller), do: :ok
  defp can_list_property?(_), do: {:error, :unauthorized}

  defp authorize_owner(%{owner_id: nil}, _), do: :ok
  defp authorize_owner(%{owner_id: owner_id}, %{id: user_id}) when owner_id == user_id, do: :ok
  defp authorize_owner(_, _), do: {:error, :unauthorized}
end
