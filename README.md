# Bill Splitting API

Rails backend skeleton for the bill-splitting app (Fetza), based on the Codehesion Rails view template.

## Stack

- Rails 8.1 (full stack with admin views)
- PostgreSQL (primary + Solid Queue / Solid Cache / Solid Cable databases)
- Active Job → **Solid Queue** (no Sidekiq/Redis)
- mission_control-jobs for job monitoring
- Devise + Doorkeeper (present from template; mobile auth not wired yet)
- rack-cors for Expo development

## Requirements

- Ruby 3.4.9 (latest Ruby 3 — see `.ruby-version`)
- PostgreSQL 16+
- libpq (`brew install libpq` and add to PATH)

## Setup

```bash
cd rails
cp .env.example .env
# Edit .env if your Postgres user/password differ from local defaults

export PATH="/opt/homebrew/opt/ruby@3.4/bin:/opt/homebrew/opt/libpq/bin:/opt/homebrew/opt/postgresql@16/bin:$PATH"

bundle install
bundle exec rails db:create db:migrate
bundle exec rails db:schema:load:queue db:schema:load:cache db:schema:load:cable
```

### Credentials

Per-environment keys live in `config/credentials/*.key` (gitignored). After cloning, run:

```bash
EDITOR="./tmp/credentials_editor.sh" bundle exec rails credentials:edit --environment development
```

Or regenerate keys with `rails credentials:edit` if you have the team's keys.

## Run

```bash
bundle exec rails server
```

## Mobile API

Health check (no auth):

```
GET /api/mobile/v1/health
```

Response:

```json
{
  "status": "ok",
  "app": "bill-splitting-api"
}
```

Point the Expo app at `http://localhost:3000` (or your machine IP) in development. CORS allows localhost, Expo `exp://` URLs, and `*.exp.direct` tunnels.

## Jobs

```bash
# Optional: run Solid Queue inside Puma
SOLID_QUEUE_IN_PUMA=1 bundle exec rails server

# Or run the queue worker separately
bundle exec rails solid_queue:start
```

Mission Control: mount is available via the `mission_control-jobs` gem (configure mount in routes when needed).
