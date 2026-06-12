defmodule ElixirApp.Workers.NewOfferEmailWorker do
  use Oban.Worker, queue: :mailers, max_attempts: 3
  require Logger

  alias ElixirApp.{Accounts, Emails, Mailer}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"seller_id" => seller_id, "buyer_name" => buyer_name,
                                "property_title" => property_title, "amount" => amount}}) do
    seller = Accounts.get_user(seller_id)

    if seller do
      result =
        seller
        |> Emails.new_offer_email(buyer_name, property_title, amount)
        |> Mailer.deliver()

      case result do
        {:ok, _} -> Logger.info("[Mailer] new_offer email sent to #{seller.email}")
        {:error, reason} -> Logger.error("[Mailer] failed to send to #{seller.email}: #{inspect(reason)}")
      end
    else
      Logger.warning("[Mailer] seller_id=#{seller_id} not found, skipping email")
    end

    :ok
  end
end
