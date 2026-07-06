# Site Completion Implementation Plan (CV, Writing, Contact, RSS, SEO)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox syntax.

**Goal:** Build the remaining pages (CV at /cv, Writing index + posts at /writing, Contact at /contact), RSS, and per-page SEO so every nav link resolves and the whole site matches the locked mockups.

**Architecture:** Same file-based pattern as the Work page: POROs over content files, skinny controllers, ERB views translated from the locked mockups in `docs/design-mockups/`, Tailwind tokens already defined (page/ink/ink2/muted/coral/coral-d/line/avail, font-display/body/mono). Stimulus for the one interactive behaviour (Copy for AI clipboard).

**Tech Stack:** Rails 8.1, RSpec, Commonmarker (GFM, hardbreaks off), Tailwind v4 tokens, Hotwire.

## Global Constraints

- No em-dashes anywhere; date ranges use plain hyphens. Brands are delivered-for, never clients.
- No service objects; POROs in app/models. Skinny controllers. No Active Record for content.
- The mockups are the design source of truth: `docs/design-mockups/cv.html`, `docs/design-mockups/blog.html`, `docs/design-mockups/contact.html`. Translate their layout/typography faithfully to ERB + the existing Tailwind theme tokens; reuse the existing nav/footer partials (do not duplicate them).
- Responsive: paddings `px-5 md:px-10`, grids collapse to one column below `md`, no horizontal overflow at 390px.
- TDD: request specs first for pages, model specs for POROs; genuine RED documented; full `bundle exec rspec` + `bin/rubocop` green before every commit.
- Commit messages end with: Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>

---

## Task 1: Cv PORO + /cv page + Copy for AI

**Files:**
- Create: `app/models/cv.rb`, `app/controllers/cv_controller.rb`, `app/views/cv/show.html.erb`, `app/javascript/controllers/clipboard_controller.js`
- Modify: `config/routes.rb` (`get "cv" => "cv#show"`, `get "cv.pdf" => "cv#pdf", as: :cv_pdf`)
- Test: `spec/models/cv_spec.rb`, `spec/requests/cv_page_spec.rb`
- Fixture: `spec/fixtures/content/cv.yml` (small, same shape as real `content/cv.yml`)

**Interfaces:**
- `Cv.load` returns a Cv built from `Cv.content_path` (default `Rails.root.join("content/cv.yml")`, override-able for specs like `Project.content_dir`).
- Readers: `name, title, tagline, location, email, linkedin, github, education, profile, skills (Hash), jobs (Array of Hashes with string keys; a job may have "engagements" Array), additional (Array)`.
- `#to_markdown` returns a clean markdown CV string: `# name`, title line, contact line, `## Profile`, `## Core skills` (one `- **Category:** values` per skill), `## Experience` with `### role, org (when)` + context line + `-` bullets, engagements nested as `#### role, org (when)` under Flumes, `## Additional experience`. No em-dashes.
- View: sidebar layout per `docs/design-mockups/cv.html`: left rail (name, title, PDF + Copy for AI buttons, location, email/LinkedIn/GitHub icons in light gray #b3ada2 hover coral, Core skills, Education), right column with `// Profile`, `// Experience` (spaced section labels with hairline top border), nested `// Select engagements` block indented behind a coral rail for the Flumes engagements, `// Additional experience`. Rounded coral square bullets (7px, 2px radius) via CSS.
- `CvController#show` assigns `@cv = Cv.load`; `#pdf` sends `content/cv.pdf` (`send_file ..., filename: "Steve_Butterworth_CV.pdf", type: "application/pdf", disposition: "attachment"`).
- Copy for AI: `clipboard_controller.js` Stimulus controller; the button carries `data-clipboard-text` (the `@cv.to_markdown` value) and on click writes it to `navigator.clipboard` and swaps its label to "Copied" for ~1.5s. Request spec asserts the markdown payload is embedded; a system spec is optional (clipboard permissions in headless are flaky; if unreliable, cover the controller by asserting the data attribute and skip the system test, noting it).

**Steps:** fixture + failing model spec (readers + to_markdown format) → implement Cv → failing request spec (`get "/cv"` renders name, "// Experience", "Select engagements", PDF link to /cv.pdf, copy button with data-clipboard-text) → routes/controller/view/JS → green → rubocop → commit.

---

## Task 2: Article PORO + placeholder posts

**Files:**
- Create: `app/models/article.rb`, `content/posts/2026-06-12-placeholder-first-post.md`, `content/posts/2026-05-20-placeholder-second-post.md`
- Test: `spec/models/article_spec.rb`
- Fixtures: `spec/fixtures/content/posts/*.md` (two small posts)

**Interfaces:**
- `Article.content_dir` (default `content/posts`, override-able). `Article.all` (date desc, underscore files excluded), `Article.find(slug)` (nil when missing).
- Readers: `slug` (filename without date prefix and extension: `2026-06-12-foo.md` → `foo`), `title, date (Date), author (defaults "Steve Butterworth"), tags (Array), excerpt, thumbnail (may be nil), cover (may be nil), body_html, reading_time` (max(1, words/200) minutes, from body_markdown).
- Placeholder posts: front-matter per `content/posts/_TEMPLATE.md`; bodies are clearly-placeholder prose INCLUDING one `## heading`, one list, one fenced ```ruby code block (to exercise post styling). `thumbnail` may reference existing project media (e.g. "projects/gsk-mvoc/cover.png") as a stand-in; note it in the file as a comment line in the body.

**Steps:** fixtures + failing model spec (ordering by date desc, slug parsing, reading_time, author default, find) → implement → green → placeholder content files → full suite → rubocop → commit.

---

## Task 3: Writing index + post page + RSS

**Files:**
- Create: `app/controllers/articles_controller.rb`, `app/views/articles/index.html.erb`, `app/views/articles/show.html.erb`, `app/views/articles/index.rss.builder`
- Modify: `config/routes.rb`: `get "writing" => "articles#index", as: :articles`; `get "writing/:slug" => "articles#show", as: :article`; RSS via `get "writing.rss" => "articles#index", defaults: { format: :rss }`
- Test: `spec/requests/articles_spec.rb`

**Interfaces:**
- Index per `docs/design-mockups/blog.html` (Index B, thumbnail rows): `// Writing` header + "Notes from the build." + intro; one row per article: thumbnail left (220px col; when `thumbnail` nil render an ivory placeholder block with a coral `//`), right side mono meta line (date "%-d %b %Y" · author · N min read), title, excerpt, tag pills. Whole row links to the post.
- Post per the mockup's post layout: centered ~720px column; back link "← All writing" (a real left arrow character is fine; NOT an em-dash), title, excerpt as deck, byline (author, date, reading time, tags), optional cover image, prose body. Prose styling: headings in font-display, coral square list bullets, dark code blocks (`pre` styled dark like the lightbox palette), links coral.
- `ArticlesController#show` 404s for unknown slug (`raise ActionController::RoutingError` or `head :not_found` via `render file` pattern; simplest: `@article = Article.find(params[:slug]) or raise ActionController::RoutingError, "not found"`).
- RSS: standard builder feed (title "Steve Butterworth · Writing", site URL, item per article with title/link/pubDate/description=excerpt).
- Request specs: index lists both placeholder posts with meta; show renders title + code block styling hook; unknown slug 404s; RSS responds with application/rss+xml and both items.

**Steps:** failing request specs → routes/controller/views/builder → green → rubocop → commit.

---

## Task 4: Contact page

**Files:**
- Create: `app/controllers/contacts_controller.rb`, `app/views/contacts/show.html.erb`
- Modify: `config/routes.rb` (`get "contact" => "contacts#show"`)
- Test: `spec/requests/contact_page_spec.rb`

**Interfaces:**
- Split layout per `docs/design-mockups/contact.html` variant A: left = `// Contact` eyebrow, "Let's build something." h1, pitch paragraph, availability chip, email + location rows, LinkedIn/GitHub icons; right = the form.
- Form posts to `https://api.web3forms.com/submit` (POST, standard HTML form, no Rails action): hidden `access_key` input reading `Rails.application.credentials.dig(:web3forms, :access_key) || ENV["WEB3FORMS_ACCESS_KEY"] || "REPLACE-ME"`; fields name (text, required), email (email, required), message (textarea, required); hidden honeypot `<input type="checkbox" name="botcheck" class="hidden" tabindex="-1" autocomplete="off">`; hidden `subject` ("New message from steveb.io") and `from_name` ("steveb.io contact form") inputs; submit button coral. Inputs styled: bg white-ish (#FBF9F3 like), border line, rounded, coral focus ring.
- No mailer, no POST route in Rails.
- Request spec: renders form action to web3forms, name/email/message fields, honeypot, availability chip text.

**Steps:** failing request spec → route/controller/view → green → rubocop → commit.

---

## Task 5: SEO + nav polish

**Files:**
- Modify: `app/views/layouts/application.html.erb` (meta description + OG/Twitter tags via content_for with sensible defaults), `app/views/shared/_nav.html.erb` (active link per current page), page views (`content_for :title` and `:description` on home/cv/index/show/contact)
- Create: `public/robots.txt` allow-all with sitemap line, `app/views/pages/sitemap.xml.builder` + route `get "sitemap.xml" => "pages#sitemap", defaults: { format: :xml }`
- Test: `spec/requests/seo_spec.rb`

**Interfaces:**
- Titles: home "Steve Butterworth · Software Engineer"; cv "CV · Steve Butterworth"; writing "Writing · Steve Butterworth"; article "<title> · Steve Butterworth"; contact "Contact · Steve Butterworth".
- OG: og:title (same as title), og:description, og:type website/article, og:image absolute URL (article cover or first project cover for home), twitter:card summary_large_image.
- Nav active state: coral for the section matching `request.path` (`/` exact; `/cv`, `/writing*`, `/contact` prefix).
- Sitemap: root, /cv, /writing, each article URL. Host from `request.base_url`.
- Request spec: title + og:title on each page; sitemap lists /writing and both posts; robots.txt served.

**Steps:** failing spec → implement → green → rubocop → commit.

---

Post-plan: controller-led final review and whole-site browser verification (desktop + emulated mobile, every page, print check for /cv) against the mockups.
