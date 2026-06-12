defmodule ElixirApp.RealEstate do
  use Ash.Domain

  resources do
    resource ElixirApp.RealEstate.Property
    resource ElixirApp.RealEstate.User
  end
end
