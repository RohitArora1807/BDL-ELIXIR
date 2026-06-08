defmodule ElixirApp.PropertiesTest do
  use ElixirApp.DataCase

  alias ElixirApp.Properties

  describe "properties" do
    alias ElixirApp.Properties.Property

    import ElixirApp.PropertiesFixtures

    @invalid_attrs %{status: nil, type: nil, description: nil, title: nil, location: nil, price: nil, bedrooms: nil, bathrooms: nil, area: nil}

    test "list_properties/0 returns all properties" do
      property = property_fixture()
      assert Properties.list_properties() == [property]
    end

    test "get_property!/1 returns the property with given id" do
      property = property_fixture()
      assert Properties.get_property!(property.id) == property
    end

    test "create_property/1 with valid data creates a property" do
      valid_attrs = %{status: "some status", type: "some type", description: "some description", title: "some title", location: "some location", price: "120.5", bedrooms: 42, bathrooms: 42, area: 120.5}

      assert {:ok, %Property{} = property} = Properties.create_property(valid_attrs)
      assert property.status == "some status"
      assert property.type == "some type"
      assert property.description == "some description"
      assert property.title == "some title"
      assert property.location == "some location"
      assert property.price == Decimal.new("120.5")
      assert property.bedrooms == 42
      assert property.bathrooms == 42
      assert property.area == 120.5
    end

    test "create_property/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Properties.create_property(@invalid_attrs)
    end

    test "update_property/2 with valid data updates the property" do
      property = property_fixture()
      update_attrs = %{status: "some updated status", type: "some updated type", description: "some updated description", title: "some updated title", location: "some updated location", price: "456.7", bedrooms: 43, bathrooms: 43, area: 456.7}

      assert {:ok, %Property{} = property} = Properties.update_property(property, update_attrs)
      assert property.status == "some updated status"
      assert property.type == "some updated type"
      assert property.description == "some updated description"
      assert property.title == "some updated title"
      assert property.location == "some updated location"
      assert property.price == Decimal.new("456.7")
      assert property.bedrooms == 43
      assert property.bathrooms == 43
      assert property.area == 456.7
    end

    test "update_property/2 with invalid data returns error changeset" do
      property = property_fixture()
      assert {:error, %Ecto.Changeset{}} = Properties.update_property(property, @invalid_attrs)
      assert property == Properties.get_property!(property.id)
    end

    test "delete_property/1 deletes the property" do
      property = property_fixture()
      assert {:ok, %Property{}} = Properties.delete_property(property)
      assert_raise Ecto.NoResultsError, fn -> Properties.get_property!(property.id) end
    end

    test "change_property/1 returns a property changeset" do
      property = property_fixture()
      assert %Ecto.Changeset{} = Properties.change_property(property)
    end
  end
end
