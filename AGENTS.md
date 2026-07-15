Rails 8 + Ruby 4, production app. Hotwire (Turbo + Stimulus), importmap + Propshaft.
Solid Queue / Solid Cache / Solid Cable (NO Redis, NO Sidekiq). SQLite in ALL environments,
including production. RSpec for tests. Deployed with Kamal 2. See @README.md for domain.

## Commands
- `bin/dev` — start dev server (Procfile.dev: web + jobs + assets)
- `bin/rails c` — console; `bin/rails db:migrate` / `db:rollback`
- `bin/rails g migration <Name>` — NEVER hand-edit db/schema.rb
- `bin/jobs` — run Solid Queue worker (or set SOLID_QUEUE_IN_PUMA=1)
- `bundle exec rspec` — full suite; `bundle exec rspec path/to/spec.rb:LINE` — one example
- `bin/rubocop` / `bin/rubocop -a` — lint / autofix (rubocop-rails-omakase)
- `bin/brakeman` — security scan
- `bin/importmap pin <pkg>` — add a JS dependency
- `bin/cv-pdf content/_<app>_cv.html` — print a CV to a two-page PDF (workflow: `.claude/skills/cv-pdf`)
- Deploy: `kamal deploy`; `kamal console`; `kamal logs`; `kamal app exec --primary "bin/rails db:migrate"`

YOU MUST run `bundle exec rspec` and `bin/rubocop` before considering any task complete.

## Planning (superpowers)
- When writing a superpowers implementation plan for a feature that touches more
  than one layer, Task 1 MUST be a vertical **tracer bullet**, not a horizontal
  slice: the thinnest path that runs end to end through every layer the feature
  touches (route to controller to model to view, or job to model to storage),
  as real wired code, TDD'd and committed. Stub the interior; the path must run.
- Add an **architecture gate** right after the tracer: before any horizontal
  task, confirm the shape holds end to end. If it does not, fix the plan now,
  while nothing is built on top of it.
- Then fan out into normal horizontal tasks via `superpowers:writing-plans` and
  `superpowers:subagent-driven-development`.
- Full mechanics live in the `tracer-bullet-planning` skill. Skip all of this
  for single-layer or trivial changes; go straight to TDD.

## Architecture
- `app/models/` — ActiveRecord models AND plain POROs. Domain logic lives here.
- `app/models/concerns/` — mixins to organize behavior within/across models.
- `app/controllers/` — skinny; RESTful resources; strong params; plain CRUD is fine.
- `app/jobs/` — Solid Queue jobs; thin, delegate to models/POROs.
- `app/views/` + `app/javascript/controllers/` — ERB + Stimulus.
- `config/routes.rb`, `config/deploy.yml`, `config/queue.yml`, `config/recurring.yml`.

## The Rails Way — where logic goes (IMPORTANT: no service objects)
- Do NOT create `app/services/` or `*Service`/`*Interactor`/`*Command` classes.
  We follow "Vanilla Rails is Plenty" (37signals): rich domain models, not a service layer.
- Put business logic on the model that owns the data, as instance methods with clear names
  (`order.place!`, not `PlaceOrderService.call(order)`).
- Extract cohesive behavior into a **concern** (`include Closable`) to organize a fat model.
- When logic spans objects or needs its own state, extract a **PORO** in `app/models/`
  (e.g. `Account::Closing::Purging.new(account).run`) and call it from the model.
- Use **form objects** (ActiveModel) for multi-model form submissions, **query objects**
  (POROs wrapping a relation) for complex reads, **validators** for reusable validation.
- Use callbacks judiciously for persistence-adjacent concerns only; avoid cross-object
  side effects in callbacks.
- **Prefer deep modules:** a narrow public interface hiding a substantial
  implementation. Same instinct as "rich domain models" above. Do NOT split a
  model or PORO just because it is long; split only to hide a distinct concern.
  The Sandi Metz size rules detect smells, they do not mandate extraction. See
  the `deep-modules` skill.

## Database (SQLite in production)
- Add DB-level constraints (NOT NULL, unique/`add_index`, `add_foreign_key`) alongside
  model validations. Always specify `dependent:` on associations.
- Scopes over class methods for reusable queries. Avoid N+1: use `includes`.
- SQLite has ONE writer at a time — keep write transactions short and fast.
- Never move/copy the live `*.sqlite3`, `-wal`, `-shm` files; they persist on the Kamal volume.
- Prefer ActiveRecord/Arel; do NOT use `find_by_sql`. Do NOT use `update_column`/`update_all`
  unless you explicitly intend to skip validations and callbacks.

## Background jobs (Solid Queue)
- All async work goes through Active Job + Solid Queue. Jobs are thin.
- Always set `retry_on`/`discard_on` with sane limits and backoff.
- ApplicationJob sets `self.enqueue_after_transaction_commit = :always`.
- Recurring/cron tasks go in `config/recurring.yml`, not the whenever gem.

## Frontend (Hotwire)
- NO React/Vue/SPA frameworks. Turbo Drive for nav, Turbo Frames for partial updates,
  Turbo Streams for form responses/real-time, Stimulus for small behaviors.
- Keep Stimulus controllers small and focused; use targets/values/outlets.
- Prefer `refresh="morph"` for frequently-updated regions.
- Add JS deps with `bin/importmap pin`; pin local modules (Propshaft has no Sprockets fallback).

## Testing (RSpec)
- FactoryBot factories in `spec/factories/`; lean factories, traits over callbacks,
  `build_stubbed` unless the DB is needed. shoulda-matchers for validations/associations.
- Prefer **request specs** for integration; fast **unit specs** for model/PORO logic;
  keep **system specs** (Capybara) sparse — critical flows only (signup, checkout).
- Assert behavior/rendered output, not `assigns`. For Hotwire, assert Turbo Stream
  target/action in request specs. Mock only external boundaries (WebMock/VCR); never internals.
- TDD: write a failing spec first, then implement, then refactor.

## Deploy (Kamal 2)
- Config in `config/deploy.yml`; secrets in `.kamal/secrets` (never commit master.key).
- A persistent `volumes:` entry holds SQLite DBs + Active Storage — required.
- `/up` health check must return 200. Migrations run on deploy.

## Do NOT
- Do NOT add service objects (see above). Do NOT hand-edit db/schema.rb.
- Do NOT add Redis, Sidekiq, or a JS bundler/Node build.
- Do NOT use `skip_before_action` to bypass auth — use a separate unauthenticated controller.
- Do NOT introduce React/Vue. Do NOT commit secrets.