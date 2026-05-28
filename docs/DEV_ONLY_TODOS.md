# Dev-only code — remove before production

See also the combined checklist in the Fetza repo: `fetza/docs/DEV_ONLY_TODOS.md`.

Search this repo: `rg 'TODO(production)'`

## Must change for production

| Item | Location |
|------|----------|
| **Mobile JWT secret** — set `DOORKEEPER_JWT_SECRET` (or `credentials.doorkeeper.jwt_secret`); the initializer raises in production if missing | `config/initializers/doorkeeper_jwt.rb`, `docs/mobile_auth.md` |
| **Fetza Mobile OAuth client** — set `FETZA_MOBILE_OAUTH_UID` / `FETZA_MOBILE_OAUTH_SECRET` for each environment; seeds generate random values otherwise | `db/seeds.rb` |
| **Migrate to PKCE** — replace the custom `/api/mobile/v1/auth/login` with Authorization Code + PKCE (`force_pkce` is already enabled) | `app/controllers/api/mobile/v1/auth_controller.rb`, `config/initializers/doorkeeper.rb`, `config/routes.rb` |
| **Fake OCR** | `app/jobs/process_receipt_job.rb` → `Receipts::FakeOcrProcessor` |
| **ngrok hosts** | `config/environments/development.rb` (dev env only — do not duplicate in production.rb) |
| **ActiveStorage host for receipt image URLs** — `ReceiptImageSerializer#url_for(blob)` only emits an absolute URL when `default_url_options` (or `ActiveStorage::Current.url_options`) is set; configure per environment before mobile relies on these | `app/serializers/api/mobile/v1/receipt_image_serializer.rb`, `config/environments/*.rb` |

## Already environment-scoped (verify before launch)

| Item | Location |
|------|----------|
| CORS Expo / localhost origins | `config/initializers/cors.rb` (`Rails.env.development?` only) |
| Detailed API error messages | `base_controller.rb` → `expose_exception_message?` |
| `rack-attack` enabled outside test | `config/initializers/rack_attack.rb` |
| Dev login `dev@fetza.local / password123` + sample bills | `db/seeds.rb` (non-production branch only) |
