defmodule ElixirAppWeb.CoreComponents do
  use Phoenix.Component

  # Flash messages
  attr :flash, :map, default: %{}

  def flash_group(assigns) do
    ~H"""
    <div class="flash-wrap">
      <%= for {kind, msg} <- @flash do %>
        <div class={if kind == "error", do: "flash-msg flash-error", else: "flash-msg flash-info"}>
          <%= if kind == "error", do: "✕", else: "✓" %>
          <%= msg %>
        </div>
      <% end %>
    </div>
    """
  end

  # Button
  attr :type, :string, default: "button"
  attr :rest, :global

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button type={@type} class="btn btn-primary" {@rest}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  # Badge
  attr :color, :string, default: "gray"
  slot :inner_block, required: true

  def badge(assigns) do
    cls =
      case assigns.color do
        "green"  -> "badge badge-green"
        "red"    -> "badge badge-red"
        "yellow" -> "badge badge-yellow"
        _        -> "badge badge-gray"
      end

    assigns = assign(assigns, :cls, cls)

    ~H"""
    <span class={@cls}><%= render_slot(@inner_block) %></span>
    """
  end

  # Card
  attr :rest, :global
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div class="card card-pad" {@rest}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  # Form input with label and inline error — three function heads for textarea/select/input

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, default: nil
  attr :type, :string, default: "text"
  attr :options, :list, default: []
  attr :rest, :global, include: ~w(min max step required placeholder rows style)

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div>
      <%= if @label do %>
        <label class="form-label" for={@field.id}><%= @label %></label>
      <% end %>
      <textarea
        id={@field.id}
        name={@field.name}
        class={"form-input #{if @field.errors != [], do: "input-error"}"}
        rows="3"
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @field.value) %></textarea>
      <%= for {msg, _} <- @field.errors do %>
        <span class="field-error"><%= msg %></span>
      <% end %>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div>
      <%= if @label do %>
        <label class="form-label" for={@field.id}><%= @label %></label>
      <% end %>
      <select
        id={@field.id}
        name={@field.name}
        class={"form-input #{if @field.errors != [], do: "input-error"}"}
        {@rest}
      >
        <%= for {label, value} <- @options do %>
          <option value={value} selected={to_string(@field.value) == to_string(value)}>
            <%= label %>
          </option>
        <% end %>
      </select>
      <%= for {msg, _} <- @field.errors do %>
        <span class="field-error"><%= msg %></span>
      <% end %>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div>
      <%= if @label do %>
        <label class="form-label" for={@field.id}><%= @label %></label>
      <% end %>
      <input
        id={@field.id}
        name={@field.name}
        type={@type}
        value={Phoenix.HTML.Form.normalize_value(@type, @field.value)}
        class={"form-input #{if @field.errors != [], do: "input-error"}"}
        {@rest}
      />
      <%= for {msg, _} <- @field.errors do %>
        <span class="field-error"><%= msg %></span>
      <% end %>
    </div>
    """
  end

  # Stat card for dashboard
  attr :label, :string, required: true
  attr :value, :any,    required: true
  attr :color, :string, default: "#4f46e5"

  def stat_card(assigns) do
    {icon, bg} =
      case assigns.label do
        "Total"     -> {"🏘", "#eef2ff"}
        "Available" -> {"✅", "#dcfce7"}
        "Sold"      -> {"💰", "#fee2e2"}
        "Rented"    -> {"🔑", "#fffbeb"}
        _           -> {"•",  "#f1f5f9"}
      end

    assigns = assigns |> assign(:icon, icon) |> assign(:bg, bg)

    ~H"""
    <div class="stat-card">
      <div class="stat-icon-box" style={"background:#{@bg};"}>
        <span style="font-size:1.2rem;line-height:1;"><%= @icon %></span>
      </div>
      <div>
        <div class="stat-number" style={"color:#{@color};"}><%= @value %></div>
        <div class="stat-label"><%= @label %></div>
      </div>
    </div>
    """
  end
end
