defmodule ElixirAppWeb.Router do
  use ElixirAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ElixirAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug ElixirAppWeb.Plugs.Auth
  end

  pipeline :require_live_auth do
    plug ElixirAppWeb.Plugs.LiveAuth
  end

  scope "/", ElixirAppWeb do
    pipe_through :browser
    get "/", PageController, :index
  end

  # Auth routes — no login required
  scope "/", ElixirAppWeb do
    pipe_through :browser

    live "/login",    AuthLive.Login,    :index
    live "/register", AuthLive.Register, :index
    post "/session",          SessionController,      :create
    post "/register-account", RegistrationController, :create
    get  "/logout",           SessionController,      :delete
  end

  # LiveView routes — must be logged in
  scope "/app", ElixirAppWeb do
    pipe_through [:browser, :require_live_auth]

    live "/dashboard",           DashboardLive.Index,    :index
    live "/properties",          PropertyLive.Index,     :index
    live "/properties/new",      PropertyLive.Index,     :new
    live "/properties/:id",      PropertyLive.Show,      :show
    live "/properties/:id/edit", PropertyLive.Show,      :edit
    live "/offers",              OfferLive.Index,        :index
    live "/notifications",       NotificationLive.Index, :index

    # ── Ash pages (purple) — mirrors the Ecto pages but uses Ash queries + policies ──
    live "/ash",                       AshDashboardLive.Index,  :index
    live "/ash/properties",            AshPropertyLive.Index,   :index
    live "/ash/properties/new",        AshPropertyLive.Form,    :new
    live "/ash/properties/:id",        AshPropertyLive.Show,    :show
    live "/ash/properties/:id/edit",   AshPropertyLive.Form,    :edit
    live "/ash/offers",                AshOfferLive.Index,      :index
    live "/ash/favorites",             AshFavoriteLive.Index,   :index
    live "/ash/metrics",               AshMetricLive.Index,     :index
    live "/ash/comparison",            AshComparisonLive.Index, :index
  end

  # Public auth routes — no token required
  scope "/api", ElixirAppWeb do
    pipe_through :api

    post "/register", UserController, :register
    post "/login",    UserController, :login
  end

  # Protected routes — valid token required
  scope "/api", ElixirAppWeb do
    pipe_through [:api, :auth]

    get "/me", UserController, :me

    resources "/properties", PropertyController, except: [:new, :edit]
    resources "/favorites",  FavoriteController, only: [:index, :create, :delete]
    resources "/offers",     OfferController,    except: [:new, :edit]

    get    "/notifications",           NotificationController, :index
    put    "/notifications/mark_read", NotificationController, :mark_read
    delete "/notifications",           NotificationController, :clear
  end

  # Admin routes — auth plug runs, controller enforces admin role
  scope "/api/admin", ElixirAppWeb do
    pipe_through [:api, :auth]

    get    "/users",     AdminController, :index
    patch  "/users/:id", AdminController, :update
    put    "/users/:id", AdminController, :update
  end

  if Application.compile_env(:elixir_app, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: ElixirAppWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
