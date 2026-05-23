# Bill Splitting API

Rails backend for the Fetza bill-splitting app.

## Stack

- Rails 8.1 (full stack with admin views)
- PostgreSQL (primary + Solid Queue / Solid Cache / Solid Cable databases)
- Active Job → **Solid Queue** (no Sidekiq/Redis)
- mission_control-jobs for job monitoring
- Devise + Doorkeeper (mobile bearer-token auth — see [`docs/mobile_auth.md`](docs/mobile_auth.md))
- rack-cors for Expo development

## Requirements

- [asdf](https://asdf-vm.com/) with the Ruby plugin
- Ruby 3.4.9 (see `.ruby-version` / `.tool-versions`)
- PostgreSQL 16+
- libpq (`brew install libpq postgresql@16`)

## Setup

```bash
# One-time: asdf + Ruby (if not already installed)
asdf plugin add ruby https://github.com/asdf-community/asdf-ruby.git
asdf install ruby 3.4.9   # reads .ruby-version / .tool-versions

cd rails
cp .env.example .env
# Edit .env if your Postgres user/password differ from local defaults

# Postgres tools on PATH (Ruby comes from asdf shims)
export PATH="/opt/homebrew/opt/libpq/bin:/opt/homebrew/opt/postgresql@16/bin:$PATH"

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

See [`docs/mobile_auth.md`](docs/mobile_auth.md) for the full authentication
guide (endpoints, response shape, dev credentials, curl examples, JWT secret
configuration, refresh-token rotation, and the path to PKCE).

Health check (no auth):

```
GET /api/mobile/v1/health
```

```json
{ "status": "ok", "app": "bill-splitting-api" }
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
