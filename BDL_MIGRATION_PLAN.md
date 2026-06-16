# BidLightning — Full Platform Rebuild Plan
## Elixir Backend + Phoenix LiveView Frontend

---

## Overview

We are rebuilding the BidLightning platform from scratch using **Elixir + Phoenix LiveView** — replacing the existing Python (FastAPI) backend and React (Next.js) frontend with a single unified codebase.

The existing site stays live throughout. We migrate one feature group at a time. Users experience zero downtime.

Proxy bidding engine is **excluded from this plan** — it follows as a separate release after the core platform is live.

---

## How Design Reuse Works

The existing React/Next.js project has all the CSS — colors, fonts, cards, buttons, spacing. We copy that stylesheet directly into Phoenix on Day 1. Every page we build from that point forward looks identical to the current site. We are rebuilding the functionality, not the visual design.

| React/Next.js | Phoenix LiveView |
|---------------|-----------------|
| CSS stylesheets | Copied directly — zero redesign |
| Fonts and colors | Identical |
| Cards, buttons, forms | Rebuilt as Phoenix components, same visual output |
| Page layouts | Same grid, same spacing |
| Real-time updates | Better — LiveView handles this natively, no Socket.IO needed |

The only visible difference to users: pages will feel faster. LiveView sends only the changed part of the page over the wire — not the entire page like a traditional React app.

---

## Project Structure — Pure Ash (Set Up on Day 1)

In pure Ash, every domain has one **Ash Domain** file and a set of **Ash Resource** files. There are no manual context functions, no manual changesets, no scattered authorization checks. The Resource file is the single source of truth for a model — its fields, actions, validations, and policies all live in one place.

```
bdl/
├── lib/
│   │
│   ├── bdl/                              # Business logic — no web code in here
│   │   │
│   │   ├── accounts/                     # Ash Domain: users, auth, profiles
│   │   │   ├── accounts.ex               # Ash Domain — declares which resources belong here
│   │   │   ├── user.ex                   # Ash Resource — fields, actions, policies, validations
│   │   │   ├── buyer_profile.ex          # Ash Resource
│   │   │   ├── seller_profile.ex         # Ash Resource
│   │   │   └── tokens.ex                 # JWT generation + verification (plain Elixir module)
│   │   │
│   │   ├── properties/                   # Ash Domain: listings, messages, favourites
│   │   │   ├── properties.ex             # Ash Domain
│   │   │   ├── property.ex               # Ash Resource — full CRUD actions + owner policy
│   │   │   ├── property_message.ex       # Ash Resource
│   │   │   ├── favourite.ex              # Ash Resource
│   │   │   └── homepage_content.ex       # Ash Resource
│   │   │
│   │   ├── auctions/                     # Ash Domain: sales, bids, flex bidding
│   │   │   ├── auctions.ex               # Ash Domain
│   │   │   ├── property_sale.ex          # Ash Resource — auction lifecycle state machine
│   │   │   ├── bid_attempt.ex            # Ash Resource — bid placement + validation
│   │   │   ├── bid_event.ex              # Ash Resource — append-only audit log
│   │   │   └── flex_bid.ex               # Ash Resource — flex offer state machine
│   │   │
│   │   ├── payments/                     # Plain Elixir modules (Stripe has no Ash layer)
│   │   │   └── stripe.ex                 # Stripe API wrapper — create customer, setup intent, webhook
│   │   │
│   │   ├── notifications/                # Plain Elixir modules
│   │   │   ├── emails.ex                 # Swoosh email templates
│   │   │   └── novu.ex                   # Novu HTTP wrapper for push notifications
│   │   │
│   │   └── workers/                      # Oban background jobs
│   │       ├── auction_end_worker.ex     # Scheduled at auction end time — closes auction, emails winner
│   │       └── auction_reminder_worker.ex # Fires 1 hour before close — notifies watchers
│   │
│   └── bdl_web/                          # Web layer — routing + rendering only
│       │
│       ├── live/                         # LiveView pages — call Ash directly, no manual functions
│       │   ├── auth/
│       │   │   ├── login_live.ex         # Calls Accounts domain
│       │   │   └── register_live.ex      # Calls Accounts domain
│       │   ├── properties/
│       │   │   ├── index_live.ex         # Ash.Query.filter → Ash.read!
│       │   │   ├── show_live.ex          # Ash.get → render
│       │   │   └── form_live.ex          # AshPhoenix.Form.for_create / for_update
│       │   ├── auctions/
│       │   │   ├── show_live.ex          # Live bid feed — PubSub + Ash.get
│       │   │   └── flex_bid_live.ex      # AshPhoenix.Form for flex offer
│       │   ├── admin/
│       │   │   ├── dashboard_live.ex
│       │   │   ├── properties_live.ex
│       │   │   ├── users_live.ex
│       │   │   ├── buyers_live.ex
│       │   │   └── sellers_live.ex
│       │   └── inspector/
│       │       └── portal_live.ex
│       │
│       ├── controllers/                  # JSON only — Stripe webhooks (not LiveView)
│       │   └── webhook_controller.ex
│       │
│       ├── channels/                     # Phoenix Channels — real-time auction price feed
│       │   └── auction_channel.ex
│       │
│       ├── components/                   # Reusable UI pieces
│       │   ├── core_components.ex        # Buttons, inputs, badges, modals, flash
│       │   └── auction_components.ex     # Countdown timer, live price, bid history feed
│       │
│       ├── plugs/
│       │   └── auth.ex                   # Reads JWT, puts current_user in conn assigns
│       │
│       └── router.ex
│
├── assets/
│   ├── css/
│   │   └── app.css                       # CSS copied from React project on Day 1
│   └── js/
│       └── app.js                        # LiveView hooks (countdown timer JS, etc.)
│
├── priv/
│   └── repo/
│       ├── migrations/                   # Generated by: mix ash.codegen → mix ecto.migrate
│       └── seeds.exs
│
├── config/
│   ├── config.exs                        # Shared — Ash domains registered here
│   ├── dev.exs
│   ├── prod.exs
│   └── runtime.exs                       # Secrets: DB password, Stripe key, JWT secret
│
└── test/
    ├── bdl/                              # Ash resource + domain tests
    ├── bdl_web/                          # LiveView tests
    └── support/
        └── factory.ex                    # Test data factories
```

---

### How Ash Changes the Rules

In a standard Phoenix project you write functions like this for every model:

```
def get_user(id) ...
def list_users() ...
def create_user(attrs) ...
def update_user(user, attrs) ...
def delete_user(user) ...
```

In pure Ash **you write none of that.** Instead, every Resource declares its own actions:

```
user.ex        → defines :read, :create, :update, :destroy actions + policies
property.ex    → defines :read, :create, :update, :destroy + owner policy
flex_bid.ex    → defines :submit, :accept, :reject, :counter + state machine
```

Then anywhere in the codebase — LiveView, worker, controller — you call:

```
Ash.get(User, id, actor: current_user)          # policy checked automatically
Ash.read!(Property, actor: current_user)        # returns only what policy allows
Ash.create(FlexBid, attrs, actor: current_user) # validation + policy in one call
```

**Authorization is impossible to forget** because it runs inside Ash on every call, not in the LiveView where you might skip it.

---

### The Golden Rule

> **LiveViews call Ash. Ash enforces the rules. LiveViews only render.**
>
> No business logic, no authorization checks, no validation code inside LiveView files.
> Every rule lives in the Resource. One place. Always enforced.

---

## Week 1 — Foundation + Auth Pages

| Day | What Gets Built | What Users See |
|-----|----------------|----------------|
| 1 | Project setup + full folder structure (as above) + database schema + CSS imported from React project | Blank Phoenix app with master-level structure in place, looks exactly like the current BidLightning site |
| 2 | Login & registration — backend logic + pages | Working login page, registration page, secure JWT auth |
| 3 | User status + profile logic | System recognises buyer / seller / admin / inspector roles |
| 4 | Buyer profile — page + form | Buyers can view and edit their profile on a dedicated page |
| 5 | Seller profile — page + form | Sellers can view and edit their profile on a dedicated page |

---

## Week 2 — Property Listings

| Day | What Gets Built | What Users See |
|-----|----------------|----------------|
| 6 | Homepage | Full homepage with hero section, featured properties, platform stats |
| 7 | Property search page | Browse and filter all properties by name, location, status, type |
| 8 | Property detail page | Full property page with photos, specs, seller info |
| 9 | Create + edit property form | Sellers fill out a form to list a new property; can edit it later |
| 10 | Publish flow + favourites + messages | Sellers publish listings; buyers save favourites and message sellers |

---

## Week 3 — Admin & Operations Pages

| Day | What Gets Built | What Users See |
|-----|----------------|----------------|
| 11 | Admin dashboard | Admins see all properties, platform stats, quick status controls |
| 12 | Inspector portal | Inspectors see assigned properties, submit inspection reports |
| 13 | User management page | Admins update roles, verify or deactivate accounts |
| 14 | Buyer activity log page | Admins see full history of each buyer's activity on the platform |
| 15 | Payment method page | Buyers add and manage their saved credit cards via Stripe |

---

## Week 4 — Auctions & Bidding Pages

| Day | What Gets Built | What Users See |
|-----|----------------|----------------|
| 16 | Email notifications | Transactional emails fire: bid confirmed, auction won, welcome, flex offer updates |
| 17 | Auction creation page | Admins and sellers create an auction — set start/end time, reserve price |
| 18 | Live bidding page | Buyers see current price, bid history, place a bid — page updates in real time |
| 19 | Flex bid — Resource + state machine | `flex_bid.ex` Ash Resource with full state machine: `pending → accepted / rejected / countered`. Actions: `:submit`, `:accept`, `:reject`, `:counter`. Policies: only verified buyers can submit; only property owner can decide |
| 20 | Flex bid — content + submission page | Buyers see the flex bidding terms for a property (cash offer, finance offer, other terms). Submission form built with AshPhoenix.Form — live validation on every field |
| 21 | Flex bid — seller decision page | Sellers see all incoming flex offers in a list. Can accept, reject, or counter each one. Page updates in real time when a new offer arrives |
| 22 | Flex bid — PDF generation | PDF summary generated for every accepted or countered flex offer. Seller and buyer both receive it by email automatically |

---

## Week 5 — Real-Time, Notifications & Launch

| Day | What Gets Built | What Users See |
|-----|----------------|----------------|
| 23 | Push notifications | In-app alerts for bid activity, auction reminders, offer decisions |
| 24 | Live auction feed | Bid price updates instantly on screen without refreshing — no Socket.IO, built into Phoenix |
| 25 | Auction countdown + status | Live countdown timer on auction pages; status changes (active → closing → sold) update in real time |
| 26 | Auto auction closing | Auctions close on schedule automatically; winner emails sent; no manual step needed |
| 27 | Go-live cutover | Old React + Python site retired; full BidLightning now running on Phoenix LiveView |

---

## Timeline Summary

| Week | Focus | Deliverable |
|------|-------|-------------|
| Week 1 | Foundation + auth | Users can log in and manage profiles |
| Week 2 | Property listings | Full browse and listing experience |
| Week 3 | Admin & operations | Internal team fully operational |
| Week 4 | Auctions & bidding | Core product live |
| Week 5 | Real-time & launch | Full platform running, React site retired |

**27 days (~5.5 weeks). One team. One codebase. Backend and frontend in the same language.**

---

## Why This Approach Is Low Risk

- The Python + React site stays live the entire time — no big-bang cutover
- Each feature is independently switched over and verified before the next one moves
- If anything goes wrong on any day, we revert that one feature only — everything else is unaffected
- Users experience zero downtime throughout the migration

---

## What Comes After (Phase 2)

Once the core platform is live on Elixir, the proxy bidding engine gets rebuilt as a dedicated sprint. This is the most technically complex component — a concurrent auction process that handles simultaneous bids, anti-sniping rules, and automatic price calculation. Elixir is significantly better suited for this than Python, and doing it last means the full platform foundation is in place before we touch it.
