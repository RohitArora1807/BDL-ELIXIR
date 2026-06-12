defmodule ElixirAppWeb.AuthLive.Register do
  use ElixirAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: {ElixirAppWeb.Layouts, :root}}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="auth-wrap">
      <div class="auth-card">
        <div class="auth-header">
          <div class="auth-logo">🏠</div>
          <div class="auth-title">Create an Account</div>
          <div class="auth-subtitle">Join EstateFlow today</div>
        </div>

        <div class="auth-body">
          <.flash_group flash={@flash} />

          <form action="/register-account" method="post">
            <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />

            <div class="form-group">
              <label class="form-label">Full Name</label>
              <input type="text" name="name" class="form-input" placeholder="Jane Smith" autocomplete="name" />
            </div>
            <div class="form-group">
              <label class="form-label">Email address *</label>
              <input type="email" name="email" required class="form-input" placeholder="you@example.com" autocomplete="email" />
            </div>
            <div class="form-group">
              <label class="form-label">Password * <span style="font-weight:400;color:var(--gray-400);">(min 6 chars)</span></label>
              <input type="password" name="password" required minlength="6" class="form-input" placeholder="••••••••" autocomplete="new-password" />
            </div>
            <div class="form-group">
              <label class="form-label">I am a...</label>
              <select name="role" class="form-input">
                <option value="buyer">Buyer — looking to make offers</option>
                <option value="seller">Seller — listing properties</option>
                <option value="buyer_seller">Both — buying and selling</option>
              </select>
            </div>
            <button type="submit" class="btn btn-primary btn-block btn-lg" style="margin-top:0.25rem;">
              Create Account →
            </button>
          </form>
        </div>

        <div class="auth-footer">
          Already have an account?
          <.link navigate={~p"/login"}>Sign in</.link>
        </div>
      </div>
    </div>
    """
  end
end
