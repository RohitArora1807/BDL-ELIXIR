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
    with {:ok, %Property{} = property} <- Properties.create_property(params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/properties/#{property}")
      |> render(:show, property: property)
    end
  end

  def update(conn, %{"id" => id, "property" => params}) do
    property = Properties.get_property!(id)

    with {:ok, %Property{} = property} <- Properties.update_property(property, params) do
      render(conn, :show, property: property)
    end
  end

  def delete(conn, %{"id" => id}) do
    property = Properties.get_property!(id)

    with {:ok, %Property{}} <- Properties.delete_property(property) do
      send_resp(conn, :no_content, "")
    end
  end
end
