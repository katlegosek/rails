# Dev-only code — remove before production

See also the combined checklist in the Fetza repo: `fetza/docs/DEV_ONLY_TODOS.md`.

Search this repo: `rg 'TODO(production)'`

## Must change for production

| Item | Location |
|------|----------|
| **Mobile auth** — Doorkeeper JWT bearer tokens (`Fetza Mobile` app); enable `EXPO_PUBLIC_AUTH_ENABLED=true` in Expo | `app/controllers/api/mobile/v1/auth_controller.rb`, `config/initializers/doorkeeper.rb` |
| **Fake OCR** | `app/jobs/process_receipt_job.rb` → `Receipts::FakeOcrProcessor` |
| **ngrok hosts** | `config/environments/development.rb` (dev env only — do not duplicate in production.rb) |

## Already environment-scoped (verify before launch)

| Item | Location |
|------|----------|
| CORS Expo / localhost origins | `config/initializers/cors.rb` (`Rails.env.development?` only) |
| Detailed API error messages | `base_controller.rb` → `expose_exception_message?` |
