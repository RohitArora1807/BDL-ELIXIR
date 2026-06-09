defmodule ElixirAppWeb.Router do
  use ElixirAppWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug ElixirAppWeb.Plugs.Auth
  end

  scope "/", ElixirAppWeb do
    pipe_through :api
    get "/", PageController, :index
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
