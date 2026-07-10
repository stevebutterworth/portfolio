# steveb.io

The source for Steve Butterworth's portfolio and CV site. A small, deliberately
plain Rails 8 application: no database for content, no JavaScript build step, no
external services to stand up before it runs.

## How it works

Content is files, not rows. Projects, writing and the CV live as Markdown and
YAML under `content/`, read at request time by plain Ruby objects (`Project`,
`Article`, `Cv`, all backed by `ContentFile`). There is no CMS and no `content`
table: editing the site means editing a file and committing it. Rendered
Markdown is cached by file path and mtime, so reads stay cheap.

SQLite is used in every environment, including production, and only by Rails
itself through Solid Queue, Solid Cache and Solid Cable. There are no domain
tables.

## Stack

- Ruby 4.0, Rails 8.1
- Hotwire (Turbo + Stimulus); importmap for JavaScript, so no bundler and no Node build
- Propshaft with Tailwind CSS
- SQLite everywhere, with Solid Queue / Solid Cache / Solid Cable (no Redis, no Sidekiq)
- RSpec, FactoryBot and Capybara
- Deployed with Kamal 2

## Getting started

Requires Ruby 4.0.5 (see `.ruby-version`) and SQLite.

```bash
bin/setup    # install gems and prepare the database
bin/dev      # start web, jobs and the asset watcher (Procfile.dev)
```

The site is then at http://localhost:3000.

## Content

| Section | Location | Format |
| --- | --- | --- |
| Work | `content/projects/*.md` | Markdown with YAML front matter |
| Writing | `content/posts/*.md` | Markdown with YAML front matter |
| CV | `content/cv.yml` | YAML |
| CV download | `content/cv.pdf` | served at `/cv.pdf` |

Add an entry by copying the neighbouring `_TEMPLATE.md`. Any file whose name
starts with `_` is skipped, so templates and drafts never render.

Routes: `/` (work), `/cv` and `/cv.pdf`, `/writing`, `/writing/:slug` and
`/writing.rss`, `/contact`, and `/sitemap.xml`.

## Tests and checks

```bash
bundle exec rspec                 # full suite
bundle exec rspec path/to:LINE    # a single example
bin/rubocop                       # lint (rubocop-rails-omakase)
bin/brakeman                      # security scan
```

Request specs cover the integration paths, fast unit specs cover the content
POROs, and a couple of system specs cover the interactive pieces.

## Deployment

Kamal 2, configured in `config/deploy.yml`. A persistent volume holds the SQLite
databases and Active Storage, migrations run on deploy, and `/up` is the health
check.

```bash
kamal deploy
```

## Use

The code is here to read. The content, images and CV are not licensed for reuse.
