defmodule ElixirAppWeb.AshPropertyLive.Form do
  use ElixirAppWeb, :live_view

  alias ElixirApp.RealEstate.Property
  alias ElixirApp.Accounts

  # ─────────────────────────────────────────────────────────────────────────
  # mount/3 — runs on every page load (HTTP + WebSocket).
  # We only load the user here; the form is built in handle_params so it
  # can differ between :new and :edit live_actions.
  # ─────────────────────────────────────────────────────────────────────────

  @impl true
  def mount(_params, session, socket) do
    {:ok, assign(socket, :current_user, load_user(session))}
  end

  # ─────────────────────────────────────────────────────────────────────────
  # handle_params/3 — called after mount and on every URL change.
  # live_action is :new or :edit depending on which route matched.
  # ─────────────────────────────────────────────────────────────────────────

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # ── :new — build a blank create form ─────────────────────────────────────
  #
  # AshPhoenix.Form.for_create wraps the Ash :create action.
  # It reads the action's accepted fields and validations automatically.
  # No manual changeset, no manual error mapping needed.
  #
  # actor: current_user → passed to every Ash action so policies can check
  # who is making the request. Without this, policy forbids the call.

  defp apply_action(socket, :new, _params) do
    actor = socket.assigns.current_user

    form =
      AshPhoenix.Form.for_create(Property, :create,
        actor: actor,
        domain: ElixirApp.RealEstate,
        as: "property"
      )

    socket
    |> assign(:page_title, "List a Property (Ash Form)")
    |> assign(:property, nil)
    |> assign(:form, to_form(form))
  end

  # ── :edit — load the property, build a pre-filled update form ────────────
  #
  # AshPhoenix.Form.for_update takes the existing record and the action name.
  # It pre-populates every field with the current values automatically.

  defp apply_action(socket, :edit, %{"id" => id}) do
    actor = socket.assigns.current_user

    case Ash.get(Property, id, actor: actor, domain: ElixirApp.RealEstate) do
      {:ok, property} ->
        form =
          AshPhoenix.Form.for_update(property, :update,
            actor: actor,
            domain: ElixirApp.RealEstate,
            as: "property"
          )

        socket
        |> assign(:page_title, "Edit Property (Ash Form)")
        |> assign(:property, property)
        |> assign(:form, to_form(form))

      {:error, _} ->
        socket
        |> put_flash(:error, "Property not found or access denied.")
        |> push_navigate(to: ~p"/app/properties")
    end
  end

  # ─────────────────────────────────────────────────────────────────────────
  # handle_event "validate" — called on every keystroke (phx-change).
  #
  # AshPhoenix.Form.validate runs the Ash validations defined in the
  # resource against the current params WITHOUT saving to the DB.
  # Errors surface on the form immediately — no custom error mapping.
  #
  # socket.assigns.form.source → the underlying AshPhoenix.Form struct.
  # (to_form wraps it in Phoenix.HTML.Form; .source unwraps it)
  # ─────────────────────────────────────────────────────────────────────────

  @impl true
  def handle_event("validate", %{"property" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form.source, params)
    {:noreply, assign(socket, :form, to_form(form))}
  end

  # ─────────────────────────────────────────────────────────────────────────
  # handle_event "save" — called on form submit (phx-submit).
  #
  # AshPhoenix.Form.submit executes the Ash action (:create or :update).
  # On success → redirect to the property page.
  # On failure → Ash validation errors are already in the form struct;
  #              re-assign so the template shows them inline.
  # ─────────────────────────────────────────────────────────────────────────

  @impl true
  def handle_event("save", %{"property" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form.source, params: params) do
      {:ok, property} ->
        {:noreply,
         socket
         |> put_flash(:info, "Property saved successfully!")
         |> push_navigate(to: ~p"/app/ash/properties/#{property.id}")}

      {:error, form} ->
        # form already contains all errors from Ash validations
        {:noreply, assign(socket, :form, to_form(form))}
    end
  end

  # ─────────────────────────────────────────────────────────────────────────
  # Helpers
  # ─────────────────────────────────────────────────────────────────────────

  defp load_user(%{"user_id" => id}), do: Accounts.get_user(id)
  defp load_user(_), do: nil
end
