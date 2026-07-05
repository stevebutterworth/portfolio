# steveb.io Personal Site, Design Spec

Date: 2026-07-02
Status: Approved design, ready for implementation planning
Author: Steve Butterworth (with Claude)

## 1. Overview

A personal website for Steve Butterworth at **steveb.io**: a senior Ruby on Rails
engineer and creative technologist. The site sells engineering skill first, wrapped
in a polished, editorial visual design. Four areas (five page templates, since the
blog has both an index and a post view):

1. **Portfolio** (root `/`), a single long page of selected projects.
2. **CV** (`/cv`), a polished, scannable CV with a static PDF download and a
   "Copy for AI" button.
3. **Blog / Writing** (`/writing`), a markdown-driven blog: index + post pages.
4. **Contact** (`/contact`), a simple form that emails Steve via a third-party
   endpoint (no backend mailer).

All content is **file-based markdown/YAML in the repo**. There is no database-backed
CMS and no admin UI; publishing is `git push` + deploy. Rails 8 acts as a renderer
over content files.

### Goals
- Showcase engineering depth (tech stacks, outcomes, real writeups), not just visuals.
- Distinctive, consistent design in the vein of builtproperly.co.uk / leedflow.io /
  Anthropic: warm, editorial, confident.
- Zero-friction authoring: edit a file, push, done.
- Fast, cheap to run, easy to maintain, boringly reliable.

### Non-goals (YAGNI)
- No database-backed content, no admin UI, no user accounts or auth.
- No React/Vue/SPA. No JS bundler/Node build (importmap + Propshaft only).
- No comments, no analytics dashboard, no newsletter (can be added later).
- No server-side PDF generation (PDF is a hand-made static file).

## 2. Design system

The single source of truth for look and feel. Final HTML mockups live in
`docs/design-mockups/` (`portfolio.html`, `cv.html`, `blog.html`, `contact.html`).

- **Direction:** "Crisp Grotesk". Structured, techy, editorial.
- **Typography:**
  - Display / UI: **Space Grotesk** (500/600/700).
  - Body / prose: **Inter** (400/500).
  - Labels, meta, tags, code: **Space Mono** (400/700).
  - Fonts loaded from Google Fonts (acceptable dependency; can self-host later).
- **Colour:**
  - Background (body): `#F9F6F0` (soft ivory).
  - Ink (text): `#0B0B0C`; secondary `#3a3733`; muted `#6b6b70`.
  - Accent (coral): `#E0613A`; dark variant `#c2502e`.
  - Hairlines / borders: `#e2ddd0`.
  - Availability green: `#159a5b`.
- **Ident mark:** a coral `//` in Space Mono, top-left beside "Steve Butterworth".
  Echoed in the footer ("// Let's build something.") and as the section-label
  prefix ("// Selected work", "// Experience").
- **Motifs:**
  - Section labels: Space Mono, uppercase, coral, prefixed with `//`.
  - Bullets: small rounded coral squares (7px, 2px radius), never em-dashes.
  - Tech tags: Space Mono in hairline-bordered pills.
  - Cards/frames: 14px radius; subtle shadows; hairline borders.
- **Writing style rule (hard):** **No em-dashes (—), anywhere**, in content, UI copy,
  or generated text. Use commas / colons / periods; plain hyphens for date ranges
  ("2023 - Present").
- **Nav:** sticky, `// Steve Butterworth` left; Work / CV / Writing / Contact right
  (active link in coral). Blurred ivory backdrop.
- **Footer:** `// Steve Butterworth`, email, LinkedIn + GitHub icons (light gray
  `#b3ada2`, hover coral), copyright.

## 3. Architecture

Vanilla Rails 8, "Vanilla Rails is Plenty". No service objects.

- **No Active Record for content.** Content is read from files at request time and
  parsed into plain POROs in `app/models/`.
- **Markdown:** GitHub-flavored via `commonmarker`; code highlighting via `rouge`.
- **Front-matter:** YAML front-matter parsed from each markdown file.
- **Caching:** parsed/rendered content memoized in **Solid Cache**, keyed by file
  path + mtime, so files are only parsed when changed. In development, no caching
  so edits show immediately.
- **Solid Queue / Cable** stay in the stack (Rails defaults) but are effectively
  idle; the site does no background work at launch. SQLite remains the DB for
  Solid Cache/Queue only, not for content.

### POROs (in `app/models/`)
- `Project` — loads/parses one project file; exposes `title, slug, role, year,
  tech[], cover, gallery[], video, quote, quote_author, body_html, order`.
  Class methods: `Project.all` (ordered), `Project.find(slug)`.
- `Article` — one blog post; `title, slug, date, author, tags[], excerpt,
  thumbnail, cover, reading_time, body_html`. `Article.all` (date desc),
  `Article.find(slug)`, `Article.recent(n)`.
- `Cv` — loads `content/cv.yml`; exposes `profile, skills{}, education, jobs[]`
  (each job may have nested `engagements[]`), and `to_markdown` for Copy-for-AI.
- A shared concern/PORO (`ContentFile` or `FrontMatter`) handles file reading,
  YAML front-matter split, markdown rendering, and cache keys. One clear purpose,
  reused by `Project` and `Article`.

### Controllers (skinny, RESTful)
- `PagesController#home` — portfolio at `/` (assigns `Project.all`).
- `CvController#show` — `/cv`.
- `ArticlesController#index` (`/writing`) and `#show` (`/writing/:slug`).
- `ContactsController#show` — `/contact` (static form page; submission goes to
  Web3Forms, not to Rails).
- Health check `/up` (Rails default) for Kamal.

### Routes
```
root "pages#home"
get "cv" => "cv#show"
resources :articles, path: "writing", only: [:index, :show], param: :slug
get "contact" => "contacts#show"
get "writing.rss" => "articles#index", defaults: { format: "rss" }   # RSS (optional)
```

### Frontend (Hotwire)
- Turbo Drive for navigation.
- Stimulus `lightbox_controller` — opens a modal gallery (images + video embeds)
  when a project's cover image is clicked; only present when a project has extra
  media. **Hand-rolled, no library** (the design is custom and dependency-free
  suits the importmap/Hotwire stack; reach for PhotoSwipe only if pinch/deep-zoom
  or swipe gestures ever become headline features). Design = "dark immersive":
  full dark backdrop, image centered, coral counter (`03 / 08`) + project title
  top-left, close top-right, circular prev/next arrows, thumbnail film-strip
  (active thumb coral-bordered), video thumbs show a play badge and play inline
  (Vimeo/YouTube iframe or `<video>`). Behaviour: open on cover click, close on
  ✕ / backdrop / Esc; prev/next via arrows and ← → keys; thumbnails jump slides;
  preload neighbours. Accessibility: `role="dialog"` + `aria-modal`, focus trap,
  return focus to trigger, body scroll-lock. Progressive enhancement: each gallery
  item is a real `<a href>` to the image, so it degrades to plain links without JS.
  Mockup: `docs/design-mockups/lightbox.html`.
- Stimulus `clipboard_controller` — Copy-for-AI: copies the CV markdown to the
  clipboard and shows a transient "Copied" state.
- Tailwind (tailwindcss-rails) for styling, matching the design system tokens.
- Images/video are committed static files served from `public/media/...`.

## 4. Content model & directory layout

```
content/
  projects/
    aurora-global-launch.md
    meridian-ar-experience.md
    ...
  posts/
    2026-06-12-sqlite-in-production.md
    ...
  cv.yml
  cv.pdf            # hand-made static PDF, linked from the CV page
public/
  media/
    projects/<slug>/cover.jpg, gallery-1.jpg, ...
    posts/<slug>/hero.jpg, thumb.jpg, ...
```

### Project front-matter (example)
```yaml
---
title: "Aurora Global Launch"
role: "Tech lead"
year: 2025
order: 1
tech: [Rails, Hotwire, Turbo Streams, Kamal]
cover: "projects/aurora-global-launch/cover.jpg"
gallery:
  - "projects/aurora-global-launch/1.jpg"
  - "projects/aurora-global-launch/2.jpg"
video: "https://vimeo.com/..."     # optional, embed
quote: "Steve is the rare engineer who gets the creative and still ships the hard thing."
quote_author: "Creative Director, Aurora"
---
Markdown writeup of the project...
```
- Ordering by `order` then `year` desc.
- Lightbox gallery appears only if `gallery` and/or `video` present; otherwise the
  cover is a plain (non-clickable) image.
- Every project should carry a `quote` (design shows a testimonial in each item).

### Post front-matter (example)
```yaml
---
title: "Why I run SQLite in production, and you might too"
date: 2026-06-12
author: "Steve Butterworth"
tags: [Rails, SQLite]
excerpt: "Everyone assumes you need Postgres and a fleet of servers..."
thumbnail: "posts/sqlite-in-production/thumb.jpg"
cover: "posts/sqlite-in-production/hero.jpg"
---
Markdown body, including headings, lists, pull quotes and fenced code blocks.
```
- `reading_time` computed from word count.
- Author defaults to "Steve Butterworth".

### CV (`content/cv.yml`)
Structured so the sidebar layout renders precisely:
```yaml
name: "Steve Butterworth"
title: "Senior Ruby on Rails Engineer"
location: "Ipswich, Suffolk"
email: "steve@steveb.io"
linkedin: "https://linkedin.com/in/stevebutterworth"
github: "https://github.com/..."
education: "1st Class BSc (Hons) Computer Science"
skills:
  Backend: "Rails, API design, Sidekiq, RSpec"
  Data: "PostgreSQL, Elasticsearch, Redis, Kafka, ingestion, rollups"
  Ops: "Dashboards, admin, reporting, alerting, monitoring"
  "AI/ML": "LLM classification, summarisation, cleanup, workflows"
  Practice: "Testing, CI, standards, docs, stakeholder comms"
profile: "Software engineer with 20 years' experience..."
jobs:
  - role: "Senior Rails Engineer & Product Owner"
    org: "Changeflow"
    context: "Rails monitoring & alerting product, independently built and operated"
    when: "2023 - Present"
    bullets: [ "...", "..." ]
  - role: "Independent Senior Rails Engineer & Technical Owner"
    org: "Flumes"
    context: "Independent Rails consultancy & product engineering"
    when: "2010 - Present"
    bullets: [ "...", "..." ]
    engagements:                      # nested under Flumes
      - role: "Senior Rails Engineer"
        org: "NTT Data (Contract/Seasonal)"
        context: "Engaged via LEX & Pulse Group"
        when: "2014 - 2023"
        bullets: [ "..." ]
      - { role: "Senior Rails Engineer", org: "Environmentjob.co.uk (Contract/Fractional)", ... }
      - { role: "Senior Rails Engineer", org: "GSK MVOC Analyser", context: "Engaged by AI firm Retechnica", when: "2019", ... }
  - role: "Lead Rails Engineer"
    org: "AlphaSights"
    ...
additional:                            # Additional experience section
  - { role: "Co-Founder", org: "Unicorn Studios Ipswich", when: "2019 - Present", bullets: [...] }
  - { role: "Rails & PHP Developer", org: "Humble Technologies", when: "2006 - 2008", bullets: [...] }
  - { role: "Senior Software Engineer", org: "i2, Inc. (now part of IBM)", when: "2002 - 2005", bullets: [...] }
  - { role: "Software Developer", org: "Crystal Decisions (now part of SAP)", when: "1999 - 2001", bullets: [...] }
```

## 5. Pages & behaviours

### Portfolio (`/`)
- Sticky nav. **Split full-width hero (true 50/50)**: headline left, intro +
  availability status right; the right column shares the exact left edge of the
  project text below.
- Section label `// Selected work` with a project count.
- Projects as **alternating full-width rows**: single cover image on one side
  (swapping left/right/left down the page), text on the other. Text block: ghost
  number, title, description (full width, no max-width cap), a testimonial quote
  (quiet coral left-rule), tech tags, role/year.
- Cover image: zoom-on-hover; clickable to a **lightbox gallery** only when the
  project has extra media (a small badge indicates count / video).
- Footer with contact + socials.

### CV (`/cv`)
- **Sidebar layout.** Left rail (sticky): name, title, `Download PDF` (static file)
  + `Copy for AI` buttons, location, email/LinkedIn/GitHub icons (light gray),
  Core skills, Education.
- Right main column: `// Profile`, then `// Experience` (section labels have real
  top spacing + hairline so they stand out), then `// Additional experience`.
- Experience entries: role (Space Grotesk), then company + italic context on **one
  line** (coral company, light middot separator, italic context), rounded-coral
  bullets, date on the right.
- **Flumes engagements** (NTT Data, Environmentjob, GSK) are **nested/indented**
  under the Flumes entry behind a coral rail, introduced by an indented
  `// Select engagements` label.
- Full history shown on the web CV.
- `Copy for AI`: copies a clean markdown rendering of the CV to the clipboard.
- `Download PDF`: links to `content/cv.pdf` (hand-made, kept in sync manually).

### Blog index (`/writing`)
- Header: `// Writing`, title, one-line intro.
- **Thumbnail rows**: each post is a uniform row, thumbnail left, right side has a
  Space Mono meta line (date · author · reading time), title, excerpt, tags.
  Hover tint, whole row links to the post.

### Blog post (`/writing/:slug`)
- Centered ~720px column. Back link, title, deck/excerpt, byline (avatar, date,
  reading time, tags), hero image, prose body.
- Prose supports: headings, rounded-coral bullet lists, a coral left-rule
  pull-quote, and **dark fenced code blocks** (Rouge highlighting). Author card
  with social icons at the end.

### Contact (`/contact`)
- **Split layout**: left = pitch, availability status, email, location, socials;
  right = the form (name, email, message).
- Form posts to **Web3Forms** (`https://api.web3forms.com/submit`) with a hidden
  `access_key` and a hidden honeypot field for spam. No Rails controller action
  handles the submission; success/redirect handled per Web3Forms config.
- No mailer, no SMTP, no secrets in the app. Can be swapped for a Rails-native
  Action Mailer + Resend implementation later if submissions ever need storing.

## 6. Cross-cutting concerns

- **SEO / meta:** per-page `<title>`, description, Open Graph + Twitter cards
  (project cover / post cover as the image). Sitemap.xml and robots.txt.
  RSS feed at `/writing.rss` (optional, included by default).
- **Performance:** static images with sensible sizes; Solid Cache for parsed
  content; Thruster for asset caching/compression in front of Puma.
- **Accessibility:** semantic HTML, alt text from front-matter, focus-visible
  states, keyboard-operable lightbox, adequate colour contrast on ivory.
- **Deploy:** Kamal 2, SQLite on a persistent volume (for Solid Cache/Queue).
  `content/` and `public/media/` ship in the image, so publishing = commit + deploy.
  `/up` health check returns 200.
- **Testing (RSpec):**
  - Unit specs for POROs: front-matter parsing, ordering, reading-time,
    `Cv#to_markdown`, lightbox-eligibility logic.
  - Request specs for each page: renders, correct content, meta tags, RSS format.
  - A couple of system specs for the critical JS: lightbox open/close, Copy-for-AI
    clipboard + "Copied" state.
  - Fixtures: sample content files under `spec/fixtures/content/`.

## 7. Decisions log
- Content: **all file-based markdown/YAML**, no DB, no admin.
- Direction: Crisp Grotesk; soft ivory `#F9F6F0`; coral `#E0613A`; `//` ident mark.
- Portfolio: alternating single-image rows, testimonial in each, inline (no
  click-through to a separate case study); lightbox only for extra media.
- Lightbox: dark immersive design, hand-rolled Stimulus controller (no library).
- Video: per-item, either an embed URL or a committed file.
- CV: sidebar layout, static PDF download, Copy-for-AI markdown, full history,
  Flumes engagements nested.
- Blog: thumbnail-row index + centered vanilla post; RSS included.
- Contact: dedicated split page, Web3Forms endpoint (no backend mailer).
- Hard rule: **no em-dashes anywhere**.
- Brands are **delivered for** via agencies, never called clients. Encoded in
  front-matter as `brand` + `delivered_via`, rendered as a credit line.
- Build first, real copy later: scaffold projects with placeholder body text,
  quotes and tags so the layout can be judged; real media and CV are already in.

## 8. Portfolio content (final)

Eight full pieces, curated order (visual and serious interleaved), then an
"Also delivered for" strip. Media is gathered under `public/media/projects/<slug>/`
(`cover` + numbered gallery); copy is placeholder until after the build.

| # | slug | piece | period | media |
|---|------|-------|--------|-------|
| 1 | `ntt-shotview` | ShotView, The Open (delivered for NTT DATA via LEX & Pulse Group) | 2014-2023 | cover + 6 + 2 video |
| 2 | `environmentjob` | Environmentjob.co.uk | 2013-2026 | cover + 3 |
| 3 | `emirates` | Emirates "Explore your route" (via Pulse Group) | ~2015 | cover + 2 |
| 4 | `gsk-mvoc` | GSK MVOC Analyser (via Retechnica) | 2019 | cover + 1 (reconstructed, confidential) |
| 5 | `indy-500` | Indy 500 data wall (NTT DATA via LEX) | 2020-2021 | cover + 2 |
| 6 | `changeflow` | Changeflow (own product) | 2023-2026 | cover + 3 |
| 7 | `team-gb` | Team GB Rio 2016 social data wall | 2016 | cover + 2 |
| 8 | `trackly` | Trackly (own product) | 2015-2018 | cover + 1 + video |

"Also delivered for" strip (inline row, worded as delivered-for, not clients):
Cambridge University Press, British Airways, Lenovo, Castrol, BP Pulse. Text now,
logos a later upgrade.

Note: the **GSK MVOC** cover/gallery is a **reconstructed representative dashboard**
(built as an HTML mockup, rendered to PNG), captioned "illustrative and anonymised,
client data confidential", because the original was under NDA and no assets survived.

## 9. Open items (to confirm during implementation)
- Real project copy, quotes and final tags (written after the build, against the
  live layout). Placeholders in the meantime.
- The hand-made `cv.pdf`, and the GitHub URL for the CV/footer icons.
- Web3Forms access key (free signup) for the contact form.
- Whether to self-host fonts later (currently Google Fonts).
- Optional later: Changeflow/Environmentjob deeper gallery shots; strip logos.

## References
- Final mockups: `docs/design-mockups/{portfolio,cv,blog,contact,lightbox}.html`.
- Working iterations: `.superpowers/brainstorm/references/` (gitignored).
