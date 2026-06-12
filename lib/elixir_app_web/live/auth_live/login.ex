defmodule ElixirAppWeb.AuthLive.Login do
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
          <div class="auth-title">EstateFlow</div>
          <div class="auth-subtitle">Sign in to your account</div>
        </div>

        <div class="auth-body">
          <.flash_group flash={@flash} />

          <form action="/session" method="post">
            <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
            <div class="form-group">
              <label class="form-label">Email address</label>
              <input
                type="email"
                name="email"
                required
                class="form-input"
                placeholder="you@example.com"
                autocomplete="email"
              />
            </div>
            <div class="form-group">
              <label class="form-label">Password</label>
              <input
                type="password"
                name="password"
                required
                class="form-input"
                placeholder="••••••••"
                autocomplete="current-password"
              />
            </div>
            <button type="submit" class="btn btn-primary btn-block btn-lg" style="margin-top:0.5rem;">
              Sign In →
            </button>
          </form>
        </div>

        <div class="auth-footer">
          Don't have an account?
          <.link navigate={~p"/register"}>Create one</.link>
        </div>
      </div>
    </div>
    """
  end
end
