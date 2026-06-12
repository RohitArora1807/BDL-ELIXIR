defmodule ElixirApp.Emails do
  import Swoosh.Email

  # Email to seller when a buyer submits an offer
  def new_offer_email(seller, buyer_name, property_title, amount) do
    new()
    |> to({seller.name || seller.email, seller.email})
    |> from({"Bid Lightning", "rohit.arora@mandsconsulting.com"})
    |> subject("New offer on #{property_title}")
    |> text_body("""
    Hi #{seller.name || "there"},

    You have received a new offer on your property "#{property_title}".

    Buyer: #{buyer_name}
    Offer Amount: $#{amount}

    Log in to review and respond to the offer.

    — Bid Lightning
    """)
  end

  # Email to buyer when seller accepts or rejects their offer
  def offer_update_email(buyer, property_title, status) do
    action = if status == "accepted", do: "accepted", else: "rejected"

    new()
    |> to({buyer.name || buyer.email, buyer.email})
    |> from({"Bid Lightning", "rohit.arora@mandsconsulting.com"})
    |> subject("Your offer on #{property_title} was #{action}")
    |> text_body("""
    Hi #{buyer.name || "there"},

    Your offer on "#{property_title}" has been #{action}.

    Log in to view the details and next steps.

    — Bid Lightning
    """)
  end
end
