defmodule ElixirAppWeb.PropertyLive.OfferFormComponent do
  use ElixirAppWeb, :live_component

  alias ElixirApp.Offers

  # Called once when the component is first inserted into the page.
  # Sets up the component's own private state — nothing from the parent yet.
  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:show, false)
     |> assign(:amount, "")
     |> assign(:error, nil)}
  end

  # Called every time the parent renders and passes new assigns into this component.
  # Here the parent passes: property={@property} current_user={@current_user}
  # We just store them on the socket so render/1 can use them.
  @impl true
  def update(%{property: property, current_user: current_user}, socket) do
    {:ok,
     socket
     |> assign(:property, property)
     |> assign(:current_user, current_user)}
  end

  # ---- Events — note phx-target={@myself} in the template ----
  # All three events are handled HERE, not by the parent LiveView.

  @impl true
  def handle_event("show", _params, socket) do
    {:noreply, assign(socket, show: true, error: nil)}
  end

  def handle_event("hide", _params, socket) do
    {:noreply, assign(socket, show: false, amount: "", error: nil)}
  end

  def handle_event("submit_offer", %{"amount" => amount}, socket) do
    %{property: property, current_user: current_user} = socket.assigns

    case Offers.create_offer_with_notifications(%{
      property_id: property.id,
      buyer_id:    current_user.id,
      amount:      amount,
      status:      "pending"
    }) do
      {:ok, offer} ->
        # Tell the parent LiveView to refresh its offers list.
        # send(self()) targets the parent process — the component shares the
        # parent's process, so self() IS the parent LiveView pid.
        send(self(), {:offer_submitted, offer})

        {:noreply, assign(socket, show: false, amount: "", error: nil)}

      {:error, changeset} ->
        msg = changeset.errors
              |> Enum.map(fn {k, {v, _}} -> "#{k} #{v}" end)
              |> Enum.join(", ")

        {:noreply, assign(socket, :error, msg)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @property.status == "available" && can_make_offer?(@current_user, @property) do %>
        <%= if !@show do %>
          <button phx-click="show" phx-target={@myself} class="btn btn-success">
            💬 Make an Offer
          </button>
        <% else %>
          <div class="offer-form-box">
            <p style="font-size:0.875rem;font-weight:600;color:var(--gray-800);margin-bottom:0.875rem;">
              Submit Your Offer
            </p>
            <%= if @error do %>
              <div class="alert alert-error" style="margin-bottom:0.75rem;"><%= @error %></div>
            <% end %>
            <form phx-submit="submit_offer" phx-target={@myself}>
              <div class="offer-form-row">
                <span class="offer-amount-symbol">$</span>
                <input
                  type="number"
                  name="amount"
                  value={@amount}
                  min="1"
                  step="1"
                  placeholder="Enter offer amount"
                  required
                  class="offer-input"
                />
                <button type="submit" class="btn btn-primary btn-sm">Submit</button>
                <button type="button" phx-click="hide" phx-target={@myself} class="btn btn-ghost btn-sm">
                  Cancel
                </button>
              </div>
            </form>
          </div>
        <% end %>
      <% end %>

      <%= if @current_user && @current_user.role == "seller" && !owns_property?(@current_user, @property) do %>
        <div class="seller-banner">
          Sellers cannot make offers. Switch to a buyer account to bid.
        </div>
      <% end %>
    </div>
    """
  end

  # ---- Private helpers ----

  defp can_make_offer?(nil, _property), do: false
  defp can_make_offer?(user, property) do
    user.role in ["buyer", "buyer_seller", "admin"] and user.id != property.owner_id
  end

  defp owns_property?(user, property), do: user != nil && user.id == property.owner_id
end
