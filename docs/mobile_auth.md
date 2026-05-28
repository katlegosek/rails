# Mobile API authentication

The mobile API is mounted under `/api/mobile/v1/*` and authenticates
requests with **OAuth 2 bearer tokens issued by Doorkeeper**. Access
tokens are JWTs (HS512); refresh tokens are opaque, server-side records.

## TL;DR for the mobile client

1. `POST /api/mobile/v1/auth/login` with `{ email, password }` → get
   `access_token` + `refresh_token`. Store them in `SecureStore`.
2. For every protected request, send `Authorization: Bearer <access_token>`.
3. When a request fails with `401 { error: { code: "unauthorized" } }`,
   call `POST /api/mobile/v1/auth/refresh` with `{ refresh_token }` to
   obtain a fresh pair, then retry. Refresh tokens are single-use.
4. On logout, call `POST /api/mobile/v1/auth/logout` with the bearer
   token. It revokes the current access token (and its refresh token)
   server-side; the mobile app should also drop both from `SecureStore`.

## Endpoints

| Method | Path                                        | Auth required | Notes                                   |
| ------ | ------------------------------------------- | ------------- | --------------------------------------- |
| GET    | `/api/mobile/v1/health`                     | no            | Liveness probe                          |
| POST   | `/api/mobile/v1/auth/login`                 | no            | Throttled (rack-attack)                 |
| POST   | `/api/mobile/v1/auth/refresh`               | no            | Uses `refresh_token` from request body  |
| POST   | `/api/mobile/v1/auth/logout`                | no            | Tolerant — safe to call without a token |
| GET    | `/api/mobile/v1/auth/me`                    | **yes**       | Returns the current user                |
| any    | every other `/api/mobile/v1/*` endpoint     | **yes**       | Scoped to `current_mobile_user`         |

All protected endpoints require a valid bearer token; any missing, invalid,
expired, or revoked token returns `401 Unauthorized`.

## Response shape

### Successful login / refresh

```json
{
  "access_token":  "eyJhbGciOiJIUzUxMiI...",
  "refresh_token": "p2kf1...",
  "token_type":    "Bearer",
  "expires_in":    7200,
  "user": {
    "id":         1,
    "email":      "dev@fetza.local",
    "first_name": "Dev",
    "last_name":  "User",
    "full_name":  "Dev User"
  }
}
```

The user payload is built by `Api::Mobile::V1::AuthUserSerializer` and
wrapped together with token fields by
`Api::Mobile::V1::AuthSessionSerializer`. Both live under
`app/serializers/api/mobile/v1/`. The user payload is intentionally
minimal — sensitive Devise/Doorkeeper fields (`encrypted_password`,
`reset_password_token`, OAuth secrets, etc.) are **never** exposed.

### Errors

Every mobile API error has the same JSON shape:

```json
{
  "error": {
    "code": "unauthorized",
    "message": "You need to sign in to continue."
  }
}
```

Common codes: `unauthorized`, `not_found`, `validation_error`,
`bad_request`, `processing_failed`, `rate_limited`, `server_error`.

## Curl examples

```bash
# Login
curl -i -X POST http://localhost:3000/api/mobile/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"dev@fetza.local","password":"password123"}'

# Authenticated request
ACCESS_TOKEN=...
curl -i http://localhost:3000/api/mobile/v1/auth/me \
  -H "Authorization: Bearer $ACCESS_TOKEN"

# Refresh
REFRESH_TOKEN=...
curl -i -X POST http://localhost:3000/api/mobile/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refresh_token\":\"$REFRESH_TOKEN\"}"

# Logout
curl -i -X POST http://localhost:3000/api/mobile/v1/auth/logout \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

## Dev credentials

Seeded by `db/seeds.rb` (development only):

- Email:    `dev@fetza.local`
- Password: `password123`

## OAuth grant flow

The mobile app does **not** use Doorkeeper's standard OAuth endpoints
(`/oauth/authorize`, `/oauth/token`). Instead:

- `POST /api/mobile/v1/auth/login` validates email/password with Devise
  (`User#valid_password?`) and issues an access token directly via
  `MobileAuth::TokenIssuer.issue_for(user)`.
- `MobileAuth::TokenIssuer` creates a Doorkeeper `AccessToken` row for
  the **"Fetza Mobile"** OAuth application (a public client —
  `confidential: false` — with no shared client secret).

Doorkeeper's grant flows are set to `[]` in `config/initializers/doorkeeper.rb`
to close off the public OAuth surface. The custom login keeps the mobile
client free of any client_secret.

### TODO: migrate to Authorization Code + PKCE

Switching is a larger project that needs a redirect-capable in-app
browser flow. When we're ready:

1. Add `authorization_code` to `grant_flows` in `doorkeeper.rb`
   (`force_pkce` is already enabled).
2. Mount `:authorizations` and `:tokens` in `routes.rb`
   (`use_doorkeeper { skip_controllers :all }` → only those two).
3. Build the authorization UI (Doorkeeper provides a default that we
   can scope behind Devise admin auth).
4. Replace the mobile login flow with the OS browser redirect dance.
5. Remove `/api/mobile/v1/auth/login` and the custom token issuance.

Until then the custom login endpoint is the only supported path.

## Token behaviour

| Aspect              | Value                                                              |
| ------------------- | ------------------------------------------------------------------ |
| Access token format | JWT (HS512)                                                        |
| Access token TTL    | **2 hours** (`Doorkeeper.configuration.access_token_expires_in`)   |
| Refresh tokens      | Enabled, **single-use** — see rotation note below                  |
| JWT issuer          | `fetza-mobile-api`                                                 |
| JWT `kid` header    | The mobile OAuth application UID                                   |

### Refresh token rotation

Refresh tokens are single-use. `MobileAuth::TokenIssuer#refresh`:

1. Looks up the access token row by its refresh token.
2. Returns `401` if the row is missing, expired, or revoked.
3. Revokes that row (which also invalidates the refresh token).
4. Issues a brand-new access token + refresh token pair.

Reusing a refresh token always returns `401`. The mobile app must store
the new pair returned by `/auth/refresh` and discard the old one.

## JWT signing secret

The JWT signing secret is resolved by `MobileAuth::JwtSigningSecret.fetch!`
(see `config/initializers/doorkeeper_jwt.rb`), in this order:

1. `ENV["DOORKEEPER_JWT_SECRET"]`
2. `Rails.application.credentials.dig(:doorkeeper, :jwt_secret)`
3. `Rails.application.secret_key_base` — **development/test only**.

In `Rails.env.production?` the initializer raises at boot if no explicit
secret is available. The dev fallback never runs in production.

### Setting / rotating the secret

```bash
# generate a strong key
bundle exec rails secret

# option A: ENV
heroku config:set DOORKEEPER_JWT_SECRET=...   # or your hosting equivalent

# option B: Rails credentials
EDITOR="vim" bundle exec rails credentials:edit --environment production
# add:
#   doorkeeper:
#     jwt_secret: <output of `rails secret`>
```

Rotating invalidates all currently-issued access tokens. Refresh tokens
are server-side records and **survive rotation**, so the mobile app can
recover by exchanging its refresh token for a new pair.

## Login security

- Emails are normalized (`.strip.downcase`) before lookup.
- Wrong password and unknown email both return the same generic
  `"Invalid email or password."` message — the API never reveals which
  emails are registered.
- Devise `:lockable` is configured (`maximum_attempts: 5`). The mobile
  login endpoint manually increments `failed_attempts` so accounts lock
  on repeated failed mobile logins.
- `rack-attack` adds per-IP and per-email throttles on the login
  endpoint (`config/initializers/rack_attack.rb`):
  - 10 logins per IP per minute
  - 5 logins per email per 5 minutes
  - 30 refresh requests per IP per minute

## Where to look

| Concern                          | File                                                                |
| -------------------------------- | ------------------------------------------------------------------- |
| Login / refresh / logout / me    | `app/controllers/api/mobile/v1/auth_controller.rb`                  |
| Bearer auth + error handling     | `app/controllers/api/mobile/v1/base_controller.rb`                  |
| Token issuance / rotation        | `app/services/mobile_auth/token_issuer.rb`                          |
| Auth response payload            | `app/serializers/api/mobile/v1/auth_user_serializer.rb` + `auth_session_serializer.rb` |
| Bill / receipt / participant payloads | `app/serializers/api/mobile/v1/*_serializer.rb`                |
| Doorkeeper config                | `config/initializers/doorkeeper.rb`                                 |
| JWT signing config               | `config/initializers/doorkeeper_jwt.rb`                             |
| Rate limiting                    | `config/initializers/rack_attack.rb`                                |
| Seeds (dev user + mobile client) | `db/seeds.rb`                                                       |
| Request specs                    | `spec/requests/api/mobile/v1/auth_spec.rb`                          |
| Protected-endpoint smoke spec    | `spec/requests/api/mobile/v1/protected_endpoints_spec.rb`           |
| Cross-bill scoping spec          | `spec/requests/api/mobile/v1/cross_bill_scoping_spec.rb`            |
| Config/security spec             | `spec/config/mobile_auth_security_spec.rb`                          |
