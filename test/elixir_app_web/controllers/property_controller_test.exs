defmodule ElixirAppWeb.PropertyControllerTest do
  use ElixirAppWeb.ConnCase

  import ElixirApp.PropertiesFixtures
  alias ElixirApp.Properties.Property

  @create_attrs %{
    status: "some status",
    type: "some type",
    description: "some description",
    title: "some title",
    location: "some location",
    price: "120.5",
    bedrooms: 42,
    bathrooms: 42,
    area: 120.5
  }
  @update_attrs %{
    status: "some updated status",
    type: "some updated type",
    description: "some updated description",
    title: "some updated title",
    location: "some updated location",
    price: "456.7",
    bedrooms: 43,
    bathrooms: 43,
    area: 456.7
  }
  @invalid_attrs %{status: nil, type: nil, description: nil, title: nil, location: nil, price: nil, bedrooms: nil, bathrooms: nil, area: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all properties", %{conn: conn} do
      conn = get(conn, ~p"/api/properties")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create property" do
    test "renders property when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/properties", property: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/properties/#{id}")

      assert %{
               "id" => ^id,
               "area" => 120.5,
               "bathrooms" => 42,
               "bedrooms" => 42,
               "description" => "some description",
               "location" => "some location",
               "price" => "120.5",
               "status" => "some status",
               "title" => "some title",
               "type" => "some type"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/properties", property: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update property" do
    setup [:create_property]

    test "renders property when data is valid", %{conn: conn, property: %Property{id: id} = property} do
      conn = put(conn, ~p"/api/properties/#{property}", property: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/properties/#{id}")

      assert %{
               "id" => ^id,
               "area" => 456.7,
               "bathrooms" => 43,
               "bedrooms" => 43,
               "description" => "some updated description",
               "location" => "some updated location",
               "price" => "456.7",
               "status" => "some updated status",
               "title" => "some updated title",
               "type" => "some updated type"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, property: property} do
      conn = put(conn, ~p"/api/properties/#{property}", property: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete property" do
    setup [:create_property]

    test "deletes chosen property", %{conn: conn, property: property} do
      conn = delete(conn, ~p"/api/properties/#{property}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/properties/#{property}")
      end
    end
  end

  defp create_property(_) do
    property = property_fixture()

    %{property: property}
  end
end
