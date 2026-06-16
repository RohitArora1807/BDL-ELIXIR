defmodule ElixirAppWeb.AshComparisonLive.Index do
  use ElixirAppWeb, :live_view

  alias ElixirApp.Accounts

  @impl true
  def mount(_params, session, socket) do
    {:ok, assign(socket, :current_user, load_user(session))}
  end

  @impl true
  def handle_params(_params, _url, socket), do: {:noreply, socket}

  defp load_user(%{"user_id" => id}), do: Accounts.get_user(id)
  defp load_user(_), do: nil

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <!-- Purple Ash banner -->
      <div style="background:linear-gradient(135deg,#7c3aed,#6d28d9);color:white;border-radius:12px;padding:1rem 1.5rem;margin-bottom:1.5rem;">
        <div style="font-size:1.1rem;font-weight:700;">⚡ Phoenix LiveView Only vs Phoenix LiveView + Ash</div>
        <div style="font-size:0.8rem;opacity:0.85;margin-top:0.25rem;">
          Everything on this page is built in this project — click the links to see live examples.
        </div>
      </div>

      <!-- Summary comparison table -->
      <div class="card card-pad" style="margin-bottom:1.5rem;">
        <h2 style="font-size:1rem;font-weight:700;color:#1e293b;margin-bottom:1rem;">Side-by-Side Summary</h2>
        <div style="overflow-x:auto;">
          <table style="width:100%;border-collapse:collapse;font-size:0.85rem;">
            <thead>
              <tr style="background:#f8fafc;">
                <th style="text-align:left;padding:0.6rem 0.75rem;border:1px solid #e2e8f0;color:#374151;font-weight:700;">Area</th>
                <th style="text-align:left;padding:0.6rem 0.75rem;border:1px solid #e2e8f0;color:#15803d;font-weight:700;">Phoenix LiveView Only</th>
                <th style="text-align:left;padding:0.6rem 0.75rem;border:1px solid #e2e8f0;color:#7c3aed;font-weight:700;">Phoenix LiveView + Ash</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;font-weight:600;">UI</td>
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;">LiveView pages</td>
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;">LiveView pages (identical)</td>
              </tr>
              <tr style="background:#fafafa;">
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;font-weight:600;">Business logic</td>
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;">Manual functions in Context modules</td>
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;color:#7c3aed;">Declared in Ash Resource <code>actions do</code> block</td>
              </tr>
              <tr>
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;font-weight:600;">Forms</td>
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;">Manual <code>Ecto.Changeset</code> + <code>Phoenix.HTML.Form</code></td>
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;color:#7c3aed;"><code>AshPhoenix.Form.for_create/3</code> — auto-wires validations</td>
              </tr>
              <tr style="background:#fafafa;">
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;font-weight:600;">Validations</td>
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;">Inside changeset functions — scattered, can be skipped</td>
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;color:#7c3aed;">In Resource <code>validations do</code> — run on every action, always</td>
              </tr>
              <tr>
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;font-weight:600;">Authorization</td>
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;color:#dc2626;">Manual <code>if user.role == "admin"</code> in every LiveView — easy to forget</td>
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;color:#7c3aed;">In Resource <code>policies do</code> — enforced automatically on every Ash call</td>
              </tr>
              <tr style="background:#fafafa;">
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;font-weight:600;">Relationships</td>
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;"><code>Repo.preload(record, [:owner])</code> — called manually each time</td>
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;color:#7c3aed;"><code>Ash.read!(load: [:owner, :buyer])</code> — declared in the call</td>
              </tr>
              <tr>
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;font-weight:600;">Boilerplate</td>
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;">More — write every function manually</td>
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;color:#7c3aed;">Less — Ash generates CRUD from action declarations</td>
              </tr>
              <tr style="background:#fafafa;">
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;font-weight:600;">Learning curve</td>
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;color:#15803d;">Easier to start</td>
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;color:#b45309;">Higher — but pays off fast on complex apps</td>
              </tr>
              <tr>
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;font-weight:600;">Best use</td>
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;">Simple apps, content sites, dashboards</td>
                <td style="padding:0.6rem 0.75rem;border:1px solid #e2e8f0;color:#7c3aed;font-weight:600;">Business-heavy apps like BidLightning ✓</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Live examples built in this project -->
      <h2 style="font-size:1rem;font-weight:700;color:#1e293b;margin-bottom:1rem;">Live Examples Built in This Project</h2>

      <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:1rem;margin-bottom:2rem;">
        <div class="card card-pad" style="border-top:3px solid #7c3aed;">
          <div style="font-size:0.7rem;font-weight:700;color:#7c3aed;margin-bottom:0.5rem;">RESOURCE: Property</div>
          <div style="font-weight:700;margin-bottom:0.35rem;">Policies + AshPhoenix.Form</div>
          <div style="font-size:0.8rem;color:#64748b;margin-bottom:0.75rem;">Admin full access. Seller owns listings. Buyer read-only. Form validates on every keystroke.</div>
          <.link navigate={~p"/app/ash/properties"} style="font-size:0.8rem;color:#7c3aed;font-weight:600;">View Ash Properties →</.link>
        </div>

        <div class="card card-pad" style="border-top:3px solid #7c3aed;">
          <div style="font-size:0.7rem;font-weight:700;color:#7c3aed;margin-bottom:0.5rem;">RESOURCE: Offer</div>
          <div style="font-weight:700;margin-bottom:0.35rem;">Named actions + belongs_to</div>
          <div style="font-size:0.8rem;color:#64748b;margin-bottom:0.75rem;"><code>:accept</code> and <code>:reject</code> are named Ash actions. Relationships load property + buyer in one call.</div>
          <.link navigate={~p"/app/ash/offers"} style="font-size:0.8rem;color:#7c3aed;font-weight:600;">View Ash Offers →</.link>
        </div>

        <div class="card card-pad" style="border-top:3px solid #7c3aed;">
          <div style="font-size:0.7rem;font-weight:700;color:#7c3aed;margin-bottom:0.5rem;">RESOURCE: Favorite</div>
          <div style="font-weight:700;margin-bottom:0.35rem;">Join resource + identity</div>
          <div style="font-size:0.8rem;color:#64748b;margin-bottom:0.75rem;">User ↔ Property many-to-many. <code>identities do</code> enforces one favorite per user-property pair at DB level.</div>
          <.link navigate={~p"/app/ash/favorites"} style="font-size:0.8rem;color:#7c3aed;font-weight:600;">View Ash Favorites →</.link>
        </div>

        <div class="card card-pad" style="border-top:3px solid #7c3aed;">
          <div style="font-size:0.7rem;font-weight:700;color:#7c3aed;margin-bottom:0.5rem;">RESOURCE: MetricEvent</div>
          <div style="font-weight:700;margin-bottom:0.35rem;">Append-only + no destroy policy</div>
          <div style="font-size:0.8rem;color:#64748b;margin-bottom:0.75rem;">No <code>update</code> or <code>destroy</code> policy declared → Ash forbids them automatically. Pure event log.</div>
          <.link navigate={~p"/app/ash/metrics"} style="font-size:0.8rem;color:#7c3aed;font-weight:600;">View Ash Metrics →</.link>
        </div>

        <div class="card card-pad" style="border-top:3px solid #7c3aed;">
          <div style="font-size:0.7rem;font-weight:700;color:#7c3aed;margin-bottom:0.5rem;">RESOURCE: User</div>
          <div style="font-weight:700;margin-bottom:0.35rem;">has_many relationships</div>
          <div style="font-size:0.8rem;color:#64748b;margin-bottom:0.75rem;"><code>has_many :properties</code>, <code>has_many :offers</code>, <code>has_many :favorites</code> — all defined in one place.</div>
          <.link navigate={~p"/app/ash"} style="font-size:0.8rem;color:#7c3aed;font-weight:600;">View Ash Dashboard →</.link>
        </div>
      </div>

      <!-- Detailed code comparisons -->
      <h2 style="font-size:1rem;font-weight:700;color:#1e293b;margin-bottom:1rem;">Code Deep Dives</h2>

      <div style="display:flex;flex-direction:column;gap:1.25rem;">

        <!-- Authorization -->
        <div class="card card-pad">
          <div style="font-size:0.85rem;font-weight:700;color:#1e293b;margin-bottom:0.75rem;">1. Authorization</div>
          <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;">
            <div style="background:#f0fdf4;border-radius:8px;padding:0.9rem;">
              <div style="font-size:0.7rem;font-weight:700;color:#15803d;margin-bottom:0.4rem;">ECTO — check in every LiveView</div>
              <pre style="font-size:0.7rem;color:#166534;white-space:pre-wrap;margin:0;">def handle_event("delete", _, socket) do
  user = socket.assigns.current_user
  prop = socket.assigns.property

  if user.role == "admin" do
    Properties.delete(prop)
    &#123;:noreply, push_navigate(...)&#125;
  else
    &#123;:noreply, put_flash(:error, "No access")&#125;
  end
  # Forget this check = security bug
end</pre>
            </div>
            <div style="background:#f5f3ff;border-radius:8px;padding:0.9rem;">
              <div style="font-size:0.7rem;font-weight:700;color:#7c3aed;margin-bottom:0.4rem;">ASH — declared once in the resource</div>
              <pre style="font-size:0.7rem;color:#5b21b6;white-space:pre-wrap;margin:0;"># In property.ex — runs everywhere, always:
policies do
  policy action_type(:destroy) do
    authorize_if actor_attribute_equals(:role, "admin")
  end
end

# In the LiveView — no if/else needed:
def handle_event("delete", _, socket) do
  Ash.destroy(property, actor: current_user)
  # Forbidden automatically if not admin
end</pre>
            </div>
          </div>
        </div>

        <!-- Validations -->
        <div class="card card-pad">
          <div style="font-size:0.85rem;font-weight:700;color:#1e293b;margin-bottom:0.75rem;">2. Validations</div>
          <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;">
            <div style="background:#f0fdf4;border-radius:8px;padding:0.9rem;">
              <div style="font-size:0.7rem;font-weight:700;color:#15803d;margin-bottom:0.4rem;">ECTO — in changeset functions</div>
              <pre style="font-size:0.7rem;color:#166534;white-space:pre-wrap;margin:0;">def changeset(property, attrs) do
  property
  |> cast(attrs, [:title, :price])
  |> validate_required([:title, :price])
  |> validate_length(:title, min: 3)
  |> validate_number(:price, greater_than: 0)
end
# Skipped if you call Repo.insert directly</pre>
            </div>
            <div style="background:#f5f3ff;border-radius:8px;padding:0.9rem;">
              <div style="font-size:0.7rem;font-weight:700;color:#7c3aed;margin-bottom:0.4rem;">ASH — in the resource, always enforced</div>
              <pre style="font-size:0.7rem;color:#5b21b6;white-space:pre-wrap;margin:0;">validations do
  validate present(:title)
  validate present(:price)
  validate string_length(:title, min: 3)
  validate numericality(:price, greater_than: 0)
end
# Cannot be skipped — run on every action</pre>
            </div>
          </div>
        </div>

        <!-- Relationships -->
        <div class="card card-pad">
          <div style="font-size:0.85rem;font-weight:700;color:#1e293b;margin-bottom:0.75rem;">3. Loading Relationships</div>
          <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;">
            <div style="background:#f0fdf4;border-radius:8px;padding:0.9rem;">
              <div style="font-size:0.7rem;font-weight:700;color:#15803d;margin-bottom:0.4rem;">ECTO — manual preloads</div>
              <pre style="font-size:0.7rem;color:#166534;white-space:pre-wrap;margin:0;">offer = Repo.get!(Offer, id)
offer = Repo.preload(offer, [:property, :buyer])
# Forgot :buyer? It's nil at runtime — crash</pre>
            </div>
            <div style="background:#f5f3ff;border-radius:8px;padding:0.9rem;">
              <div style="font-size:0.7rem;font-weight:700;color:#7c3aed;margin-bottom:0.4rem;">ASH — declared in the call</div>
              <pre style="font-size:0.7rem;color:#5b21b6;white-space:pre-wrap;margin:0;">Ash.get!(Offer, id,
  actor: current_user,
  load: [:property, :buyer]
)
# One call. Policy checked. Both loaded.</pre>
            </div>
          </div>
        </div>

        <!-- Named actions -->
        <div class="card card-pad">
          <div style="font-size:0.85rem;font-weight:700;color:#1e293b;margin-bottom:0.75rem;">4. Named Actions (Business Workflows)</div>
          <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;">
            <div style="background:#f0fdf4;border-radius:8px;padding:0.9rem;">
              <div style="font-size:0.7rem;font-weight:700;color:#15803d;margin-bottom:0.4rem;">ECTO — generic update</div>
              <pre style="font-size:0.7rem;color:#166534;white-space:pre-wrap;margin:0;">def accept_offer(offer) do
  offer
  |> Offer.changeset(&#37;&#123;status: "accepted"&#125;)
  |> Repo.update()
end
# Just a status field change — no context</pre>
            </div>
            <div style="background:#f5f3ff;border-radius:8px;padding:0.9rem;">
              <div style="font-size:0.7rem;font-weight:700;color:#7c3aed;margin-bottom:0.4rem;">ASH — named action models the workflow</div>
              <pre style="font-size:0.7rem;color:#5b21b6;white-space:pre-wrap;margin:0;"># In offer.ex:
update :accept do
  change set_attribute(:status, "accepted")
end

# Called as:
Ash.update(offer, action: :accept, actor: user)
# The action name IS the business intent</pre>
            </div>
          </div>
        </div>

      </div>

      <!-- Verdict for BidLightning -->
      <div style="margin-top:1.5rem;background:linear-gradient(135deg,#f5f3ff,#ede9fe);border:1px solid #ddd6fe;border-radius:12px;padding:1.25rem;">
        <div style="font-size:0.9rem;font-weight:700;color:#7c3aed;margin-bottom:0.5rem;">Is Phoenix LiveView + Ash right for BidLightning?</div>
        <div style="font-size:0.85rem;color:#5b21b6;line-height:1.7;">
          <strong>Yes.</strong> BidLightning has complex authorization (buyer, seller, admin, inspector roles),
          multiple business workflows (offer accept/reject, auction close, flex bidding states),
          and a real-time auction feed. These are exactly the problems Ash solves.
          Plain LiveView + Ecto would work, but you would write authorization checks in 30+ places
          and forget one eventually. With Ash, you write it once per resource and it is enforced everywhere.
        </div>
      </div>
    </div>
    """
  end
end
