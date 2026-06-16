defmodule ElixirApp.RealEstate do
  use Ash.Domain

  resources do
    resource ElixirApp.RealEstate.User
    resource ElixirApp.RealEstate.Property
    resource ElixirApp.RealEstate.Offer
    resource ElixirApp.RealEstate.Favorite
    resource ElixirApp.RealEstate.MetricEvent
  end
end
