defmodule ElixirApp.Workers.OfferUpdateEmailWorker do
  use Oban.Worker, queue: :mailers, max_attempts: 3
  require Logger

  alias ElixirApp.{Accounts, Emails, Mailer}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"buyer_id" => buyer_id, "property_title" => property_title,
                                "status" => status}}) do
    buyer = Accounts.get_user(buyer_id)

    if buyer do
      result =
        buyer
        |> Emails.offer_update_email(property_title, status)
        |> Mailer.deliver()

      case result do
        {:ok, _} -> Logger.info("[Mailer] offer_#{status} email sent to #{buyer.email}")
        {:error, reason} -> Logger.error("[Mailer] failed to send to #{buyer.email}: #{inspect(reason)}")
      end
    else
      Logger.warning("[Mailer] buyer_id=#{buyer_id} not found, skipping email")
    end

    :ok
  end
end
