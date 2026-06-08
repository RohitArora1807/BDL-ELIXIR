defmodule ElixirApp.PropertiesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ElixirApp.Properties` context.
  """

  @doc """
  Generate a property.
  """
  def property_fixture(attrs \\ %{}) do
    {:ok, property} =
      attrs
      |> Enum.into(%{
        area: 120.5,
        bathrooms: 42,
        bedrooms: 42,
        description: "some description",
        location: "some location",
        price: "120.5",
        status: "some status",
        title: "some title",
        type: "some type"
      })
      |> ElixirApp.Properties.create_property()

    property
  end
end
