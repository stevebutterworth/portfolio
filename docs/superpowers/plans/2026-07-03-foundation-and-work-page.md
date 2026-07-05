# Foundation + Work Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the Rails 8 site foundation (test setup, file-based content pipeline, design system, layout) and ship the Portfolio ("Work") page at `/` with alternating project rows and a hand-rolled lightbox.

**Architecture:** Vanilla Rails 8 renders file-based markdown/YAML content through plain POROs (no Active Record for content, no admin). A shared `ContentFile` parses YAML front-matter + Commonmarker markdown, memoised in Solid Cache by path+mtime. `Project` wraps `content/projects/*.md`. `PagesController#home` renders the Work page from `Project.all`; a hand-rolled Stimulus `lightbox` controller opens a dark gallery for projects with extra media. Tailwind supplies the design tokens.

**Tech Stack:** Rails 8.1, Ruby 4, RSpec, Commonmarker (GFM), Tailwind (tailwindcss-rails), Hotwire (Turbo + Stimulus via importmap), Propshaft, SQLite + Solid Cache.

## Global Constraints

These apply to every task (values copied from the spec):

- Ruby `4.0.5`, Rails `~> 8.1.3`. SQLite in all environments. Importmap + Propshaft only; **no JS bundler/Node build**.
- **No service objects** (`app/services`, `*Service`, `*Interactor`, `*Command`). Domain logic lives on models/POROs in `app/models/`.
- **No Active Record for content.** Content is files under `content/`; media under `public/media/`.
- **No em-dashes (—) anywhere** in code, comments, copy, or commit messages. Use commas/colons/hyphens.
- Recognisable brands are **delivered for** (via agencies), **never called clients**. Front-matter `brand` + `delivered_via` render as a credit line.
- Design tokens: background ivory `#F9F6F0`; ink `#0B0B0C` / secondary `#3a3733` / muted `#6b6b70`; accent coral `#E0613A` (dark `#c2502e`); hairline `#e2ddd0`; availability green `#159a5b`. Fonts: Space Grotesk (display/UI), Inter (body), Space Mono (labels/tags/mark). Ident mark: coral `//` in Space Mono.
- **TDD inner loop:** the spec files in each task are the target set, not a batch to paste in at once. Implement example-by-example: enable one example (comment out or `skip` the rest), watch it fail, write the minimal code to pass it, then enable the next. The task's "run it (passes)" step means the full spec file is green at the end.
- Run `bundle exec rspec` and `bin/rubocop` before considering any task complete.
- Migrations via `bin/rails g migration`; never hand-edit `db/schema.rb`. (No content migrations expected in this plan.)

---

## File structure (this plan)

- `Gemfile` — add `rspec-rails`, `commonmarker`, `capybara`, `selenium-webdriver`, `factory_bot_rails`.
- `app/models/content_file.rb` — PORO: read file, split front-matter/body, render markdown, cache key.
- `app/models/project.rb` — PORO: load `content/projects/*.md`, expose fields, `all`/`find`, ordering, `lightbox?`, `credit`.
- `app/controllers/pages_controller.rb` — `#home` (root).
- `config/routes.rb` — `root "pages#home"`.
- `app/views/layouts/application.html.erb` — shell: fonts, nav, footer, Tailwind.
- `app/views/shared/_nav.html.erb`, `app/views/shared/_footer.html.erb` — nav + footer partials.
- `app/views/pages/home.html.erb` — Work page: hero + project rows.
- `app/views/pages/_project.html.erb` — one alternating project row.
- `app/javascript/controllers/lightbox_controller.js` — hand-rolled gallery modal.
- `app/assets/tailwind/application.css` (or `config`) — design tokens.
- `content/projects/*.md` — 8 placeholder project files (real media paths).
- `spec/` — model specs, request spec, system spec, fixtures under `spec/fixtures/content/projects/`.

---

## Task 1: Test harness + content gems

**Files:**
- Modify: `Gemfile`
- Create: `.rspec`, `spec/spec_helper.rb`, `spec/rails_helper.rb` (via generator)
- Create: `spec/smoke_spec.rb`

**Interfaces:**
- Produces: a working `bundle exec rspec` command and the `Commonmarker` constant available app-wide.

- [ ] **Step 1: Add gems to the Gemfile**

Add to the `:development, :test` group (create the block if the group already exists, append to it):

```ruby
group :development, :test do
  gem "rspec-rails", "~> 7.1"
  gem "factory_bot_rails"
  gem "capybara"
  gem "selenium-webdriver"
end
```

Add to the top-level gems (outside any group):

```ruby
gem "commonmarker", "~> 2.0"
```

- [ ] **Step 2: Install**

Run: `bundle install`
Expected: bundle completes, `commonmarker` and `rspec-rails` resolve.

- [ ] **Step 3: Generate RSpec scaffolding**

Run: `bin/rails generate rspec:install`
Expected: creates `.rspec`, `spec/spec_helper.rb`, `spec/rails_helper.rb`.

- [ ] **Step 4: Write a smoke test**

Create `spec/smoke_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "smoke" do
  it "loads the Rails app and Commonmarker" do
    expect(Rails.application).to be_present
    expect(Commonmarker.to_html("**hi**")).to include("<strong>hi</strong>")
  end
end
```

- [ ] **Step 5: Run it**

Run: `bundle exec rspec spec/smoke_spec.rb`
Expected: 1 example, 0 failures.

- [ ] **Step 6: Commit**

```bash
git add Gemfile Gemfile.lock .rspec spec/
git commit -m "test: add rspec, commonmarker, and content gems"
```

---

## Task 2: ContentFile PORO (front-matter + markdown)

**Files:**
- Create: `app/models/content_file.rb`
- Test: `spec/models/content_file_spec.rb`
- Create fixture: `spec/fixtures/content/sample.md`

**Interfaces:**
- Produces:
  - `ContentFile.new(path)` where `path` is a `Pathname`.
  - `#data` → `Hash` of parsed YAML front-matter with **string keys** (empty hash if none).
  - `#body_markdown` → `String` (content after front-matter).
  - `#body_html` → `String` (rendered GFM HTML, memoised in `Rails.cache` keyed by `path` + `mtime`).
  - `#exists?` → `Boolean`.

- [ ] **Step 1: Write the fixture**

Create `spec/fixtures/content/sample.md`:

```markdown
---
title: "Sample"
tags: [Rails, Hotwire]
---
Hello **world**.
```

- [ ] **Step 2: Write the failing test**

Create `spec/models/content_file_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe ContentFile do
  let(:path) { Rails.root.join("spec/fixtures/content/sample.md") }
  subject(:file) { described_class.new(path) }

  it "parses front-matter into a string-keyed hash" do
    expect(file.data).to eq("title" => "Sample", "tags" => ["Rails", "Hotwire"])
  end

  it "exposes the markdown body without the front-matter" do
    expect(file.body_markdown.strip).to eq("Hello **world**.")
  end

  it "renders the body to HTML" do
    expect(file.body_html).to include("<strong>world</strong>")
  end

  it "returns an empty hash when there is no front-matter" do
    plain = Rails.root.join("spec/fixtures/content/plain.md")
    File.write(plain, "Just text.")
    expect(described_class.new(plain).data).to eq({})
  ensure
    File.delete(plain) if plain.exist?
  end
end
```

- [ ] **Step 3: Run it (fails)**

Run: `bundle exec rspec spec/models/content_file_spec.rb`
Expected: FAIL, "uninitialized constant ContentFile".

- [ ] **Step 4: Implement ContentFile**

Create `app/models/content_file.rb`:

```ruby
# Reads a content file split into optional YAML front-matter and a markdown body.
# Rendering is memoised in the Rails cache keyed by path + mtime, so files are
# only re-parsed when they change.
class ContentFile
  FRONT_MATTER = /\A---\s*\n(?<yaml>.*?)\n---\s*\n(?<body>.*)\z/m

  def initialize(path)
    @path = Pathname.new(path)
  end

  attr_reader :path

  def exists?
    path.file?
  end

  def data
    parsed[:data]
  end

  def body_markdown
    parsed[:body]
  end

  def body_html
    Rails.cache.fetch(cache_key) { Commonmarker.to_html(body_markdown) }
  end

  private

  def parsed
    @parsed ||= begin
      raw = path.read
      if (m = raw.match(FRONT_MATTER))
        { data: YAML.safe_load(m[:yaml], permitted_classes: [Date]) || {}, body: m[:body] }
      else
        { data: {}, body: raw }
      end
    end
  end

  def cache_key
    ["content_html", path.to_s, path.mtime.to_i].join("/")
  end
end
```

- [ ] **Step 5: Run it (passes)**

Run: `bundle exec rspec spec/models/content_file_spec.rb`
Expected: 4 examples, 0 failures.

- [ ] **Step 6: Commit**

```bash
git add app/models/content_file.rb spec/models/content_file_spec.rb spec/fixtures/content/sample.md
git commit -m "feat: add ContentFile for front-matter and markdown"
```

---

## Task 3: Project PORO

**Files:**
- Create: `app/models/project.rb`
- Test: `spec/models/project_spec.rb`
- Create fixtures: `spec/fixtures/content/projects/alpha.md`, `beta.md`, `_ignored.md`

**Interfaces:**
- Consumes: `ContentFile` (Task 2).
- Produces:
  - `Project.all` → `Array<Project>` from `Project::CONTENT_DIR`, excluding files whose basename starts with `_`, ordered by `order` asc then `year` desc.
  - `Project.find(slug)` → `Project` or `nil`.
  - Instance readers: `slug, title, role, brand, delivered_via, year, period, order, tech (Array), cover, gallery (Array), videos (Array), quote, quote_author, body_html`.
  - `#lightbox?` → `Boolean` (`gallery.any?` OR `videos.any?`).
  - `#credit` → `String` or `nil` (`"Delivered for <brand> via <delivered_via>"`, or `"Delivered for <brand>"` when no agency, `nil` when no brand).
  - `Project::CONTENT_DIR` is overridable in tests via `allow(Project).to receive(:content_dir)`.

- [ ] **Step 1: Write fixtures**

Create `spec/fixtures/content/projects/alpha.md`:

```markdown
---
title: "Alpha"
role: "Tech lead"
brand: "NTT DATA"
delivered_via: "LEX & Pulse Group"
year: 2022
period: "2014 - 2023"
order: 1
tech: [Rails, Kafka]
cover: "projects/alpha/cover.png"
gallery: ["projects/alpha/1.png"]
videos: ["https://vimeo.com/1", "https://www.youtube.com/watch?v=abc123"]
quote: "Great work."
quote_author: "A. Person, NTT DATA"
---
Body text for **Alpha**.
```

Create `spec/fixtures/content/projects/beta.md`:

```markdown
---
title: "Beta"
role: "Engineer"
year: 2024
order: 2
tech: [Rails]
cover: "projects/beta/cover.png"
---
Body for Beta.
```

Create `spec/fixtures/content/projects/_ignored.md`:

```markdown
---
title: "Ignore me"
order: 0
---
Template, not a project.
```

- [ ] **Step 2: Write the failing test**

Create `spec/models/project_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Project do
  before do
    allow(described_class).to receive(:content_dir)
      .and_return(Rails.root.join("spec/fixtures/content/projects"))
  end

  describe ".all" do
    it "loads projects, ignores underscore files, orders by order then year desc" do
      expect(described_class.all.map(&:slug)).to eq(%w[alpha beta])
    end
  end

  describe ".find" do
    it "returns the project for a slug" do
      expect(described_class.find("alpha").title).to eq("Alpha")
    end

    it "returns nil for an unknown slug" do
      expect(described_class.find("nope")).to be_nil
    end
  end

  describe "an instance" do
    subject(:project) { described_class.find("alpha") }

    it "exposes typed fields" do
      expect(project.tech).to eq(%w[Rails Kafka])
      expect(project.gallery).to eq(["projects/alpha/1.png"])
      expect(project.videos).to eq(["https://vimeo.com/1", "https://www.youtube.com/watch?v=abc123"])
      expect(project.body_html).to include("<strong>Alpha</strong>")
    end

    it "is lightbox-eligible when it has gallery or video" do
      expect(project.lightbox?).to be(true)
      expect(described_class.find("beta").lightbox?).to be(false)
    end

    it "builds a delivered-for credit line, never client language" do
      expect(project.credit).to eq("Delivered for NTT DATA via LEX & Pulse Group")
      expect(described_class.find("beta").credit).to be_nil
    end
  end
end
```

- [ ] **Step 3: Run it (fails)**

Run: `bundle exec rspec spec/models/project_spec.rb`
Expected: FAIL, "uninitialized constant Project".

- [ ] **Step 4: Implement Project**

Create `app/models/project.rb`:

```ruby
# A portfolio project loaded from content/projects/<slug>.md. No database.
class Project
  def self.content_dir
    Rails.root.join("content/projects")
  end

  def self.all
    Dir.glob(content_dir.join("*.md"))
       .reject { |p| File.basename(p).start_with?("_") }
       .map { |p| new(Pathname.new(p)) }
       .sort_by { |proj| [proj.order, -proj.year] }
  end

  def self.find(slug)
    path = content_dir.join("#{slug}.md")
    return nil unless path.file?

    new(path)
  end

  def initialize(path)
    @file = ContentFile.new(path)
    @slug = path.basename(".md").to_s
  end

  attr_reader :slug

  def title = data["title"]
  def role = data["role"]
  def brand = data["brand"]
  def delivered_via = data["delivered_via"]
  def year = (data["year"] || 0).to_i
  def period = data["period"]
  def order = (data["order"] || 999).to_i
  def tech = Array(data["tech"])
  def cover = data["cover"]
  def gallery = Array(data["gallery"])
  def videos = Array(data["videos"] || data["video"]).reject { |v| v.to_s.strip.empty? }
  def quote = data["quote"]
  def quote_author = data["quote_author"]
  def body_html = @file.body_html

  def lightbox?
    gallery.any? || videos.any?
  end

  def credit
    return nil if brand.blank?
    return "Delivered for #{brand}" if delivered_via.blank?

    "Delivered for #{brand} via #{delivered_via}"
  end

  private

  def data = @file.data
end
```

- [ ] **Step 5: Run it (passes)**

Run: `bundle exec rspec spec/models/project_spec.rb`
Expected: 7 examples, 0 failures.

- [ ] **Step 6: Commit**

```bash
git add app/models/project.rb spec/models/project_spec.rb spec/fixtures/content/projects/
git commit -m "feat: add Project PORO loading file-based projects"
```

---

## Task 4: Design system + layout (nav, footer, tokens)

**Files:**
- Modify: `app/views/layouts/application.html.erb`
- Create: `app/views/shared/_nav.html.erb`, `app/views/shared/_footer.html.erb`
- Modify: `app/assets/tailwind/application.css` (the tailwindcss-rails entry stylesheet)
- Test: `spec/views/shared_partials_spec.rb`

**Interfaces:**
- Consumes: nothing.
- Produces: an application layout that yields page content between a shared nav (`// Steve Butterworth` + Work/CV/Writing/Contact) and footer; design tokens available as Tailwind theme values and CSS variables. (No routes exist yet; the layout is exercised end-to-end by Task 6's request spec.)

- [ ] **Step 1: Write the failing view spec**

Create `spec/views/shared_partials_spec.rb` (a view spec: it renders the partials directly and needs no routes):

```ruby
require "rails_helper"

RSpec.describe "Shared partials", type: :view do
  it "nav renders the ident mark and links" do
    render partial: "shared/nav"
    expect(rendered).to include("Steve Butterworth")
    expect(rendered).to include("//")
    expect(rendered).to include("Work")
  end

  it "footer renders the email" do
    render partial: "shared/footer"
    expect(rendered).to include("steve@steveb.io")
  end
end
```

- [ ] **Step 2: Run it (fails)**

Run: `bundle exec rspec spec/views/shared_partials_spec.rb`
Expected: FAIL, missing partial `shared/_nav`.

- [ ] **Step 3: Add design tokens to Tailwind**

In `app/assets/tailwind/application.css`, after the `@import "tailwindcss";` line, add:

```css
@theme {
  --color-page: #F9F6F0;
  --color-ink: #0B0B0C;
  --color-ink2: #3a3733;
  --color-muted: #6b6b70;
  --color-coral: #E0613A;
  --color-coral-d: #c2502e;
  --color-line: #e2ddd0;
  --color-avail: #159a5b;
  --font-display: "Space Grotesk", system-ui, sans-serif;
  --font-body: "Inter", system-ui, sans-serif;
  --font-mono: "Space Mono", ui-monospace, monospace;
}

body { background: var(--color-page); color: var(--color-ink); font-family: var(--font-body); }
```

- [ ] **Step 4: Create the nav partial**

Create `app/views/shared/_nav.html.erb`:

```erb
<nav class="sticky top-0 z-20 flex items-center justify-between border-b border-line bg-page/85 px-10 py-5 backdrop-blur">
  <a href="/" class="flex items-center gap-2 font-display font-semibold">
    <span class="font-mono font-bold text-coral">//</span> Steve Butterworth
  </a>
  <div class="flex gap-6 font-mono text-xs uppercase tracking-widest">
    <a href="/" class="<%= current_page?("/") ? "text-coral" : "text-ink" %>">Work</a>
    <a href="/cv" class="text-ink">CV</a>
    <a href="/writing" class="text-ink">Writing</a>
    <a href="/contact" class="text-ink">Contact</a>
  </div>
</nav>
```

- [ ] **Step 5: Create the footer partial**

Create `app/views/shared/_footer.html.erb`:

```erb
<footer class="flex items-end justify-between border-t border-line px-10 py-11 text-sm text-muted">
  <div class="font-display text-3xl font-medium tracking-tight text-ink">
    <span class="font-mono text-coral">//</span> Let&rsquo;s build something.
  </div>
  <div class="text-right leading-loose">
    <a href="mailto:steve@steveb.io" class="text-ink">steve@steveb.io</a><br>
    <a href="#" class="text-ink">LinkedIn</a> &middot; <a href="#" class="text-ink">GitHub</a><br>
    <span class="text-muted">&copy; 2026 Steve Butterworth</span>
  </div>
</footer>
```

- [ ] **Step 6: Wire the layout**

Replace the `<body>` of `app/views/layouts/application.html.erb` with:

```erb
<body>
  <%= render "shared/nav" %>
  <main><%= yield %></main>
  <%= render "shared/footer" %>
</body>
```

And in the `<head>`, add the fonts link before the stylesheet tags:

```erb
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600;700&family=Inter:wght@400;500;600&family=Space+Mono:wght@400;700&display=swap" rel="stylesheet">
```

- [ ] **Step 7: Run it (passes)**

Run: `bundle exec rspec spec/views/shared_partials_spec.rb`
Expected: 2 examples, 0 failures.

- [ ] **Step 8: Commit**

```bash
git add app/views/layouts/application.html.erb app/views/shared/ app/assets/tailwind/application.css spec/views/shared_partials_spec.rb
git commit -m "feat: add design tokens, nav and footer layout"
```

---

## Task 5: Placeholder project content + media check

**Files:**
- Create: `content/projects/{ntt-shotview,environmentjob,emirates,gsk-mvoc,indy-500,changeflow,team-gb,trackly}.md`
- Test: `spec/models/project_content_spec.rb`

**Interfaces:**
- Consumes: `Project` (Task 3), the real media already in `public/media/projects/<slug>/`.
- Produces: 8 real project files with real front-matter (media paths, brand credit, order) and **placeholder** body/quote/tags, so the Work page renders against real images.

- [ ] **Step 1: Write the 8 files**

For each slug below, create `content/projects/<slug>.md`. Use the real `order`, `period`, `cover` and `gallery` (match the files in `public/media/projects/<slug>/`), a placeholder `quote`, placeholder `tech` tags, and a placeholder body. Example for `ntt-shotview` (repeat the shape for the others, adjusting slug/order/period/cover/gallery and keeping placeholders):

```markdown
---
title: "ShotView, The Open"
role: "Senior Rails engineer"
brand: "NTT DATA"
delivered_via: "LEX & Pulse Group"
year: 2022
period: "2014 - 2023"
order: 1
tech: [Placeholder, Placeholder, Placeholder]
cover: "projects/ntt-shotview/cover.png"
gallery:
  - "projects/ntt-shotview/1.png"
  - "projects/ntt-shotview/2.png"
  - "projects/ntt-shotview/3.png"
  - "projects/ntt-shotview/4.png"
  - "projects/ntt-shotview/5.png"
  - "projects/ntt-shotview/6.png"
videos:
  - "https://www.youtube.com/watch?v=ebKv9aPsotI"
  - "https://www.youtube.com/watch?v=NeCOzhro_x8"
quote: "Placeholder testimonial to be replaced with a real quote."
quote_author: "Placeholder Name, Role"
---
Placeholder project writeup. Two or three short paragraphs of copy will go here
after the build, so the real layout and spacing can be judged first. Lorem ipsum
dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt.
```

The other seven, with real `order` / `period` / media (no video except where noted):

| slug | order | period | cover | gallery count | videos |
|------|-------|--------|-------|---------------|--------|
| environmentjob | 2 | 2013 - 2026 | cover.png | 3 (1,2,3.png) | none |
| emirates | 3 | 2015 | cover.png | 2 (1,2.png) | none |
| gsk-mvoc | 4 | 2019 | cover.png | 1 (1.png) | none |
| indy-500 | 5 | 2020 - 2021 | cover.png | 2 (1,2.png) | none |
| changeflow | 6 | 2023 - 2026 | cover.png | 3 (1.jpeg,2.png,3.png) | none |
| team-gb | 7 | 2016 | cover.jpeg | 2 (1,2.jpeg) | none |
| trackly | 8 | 2015 - 2018 | cover.png | 1 (1.png) | ["https://trackly.io/video/trackly-intro-screencast.mp4"] |

(ntt-shotview above carries both YouTube films. `videos` is always a YAML list.)

For `emirates`, `gsk-mvoc`, `indy-500` set `brand`/`delivered_via` where accurate (`Emirates` via `Pulse Group`; `GSK` via `Retechnica`; `NTT DATA` via `LEX`); `environmentjob`, `changeflow`, `trackly` have no `brand` (own products / direct). Keep `tech`, `quote`, body as placeholders.

- [ ] **Step 2: Write the test**

Create `spec/models/project_content_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Real project content" do
  it "loads eight projects in curated order" do
    slugs = Project.all.map(&:slug)
    expect(slugs).to eq(%w[ntt-shotview environmentjob emirates gsk-mvoc indy-500 changeflow team-gb trackly])
  end

  it "points every cover at a file that exists in public/media" do
    Project.all.each do |project|
      cover = Rails.root.join("public/media", project.cover)
      expect(cover).to exist, "missing cover for #{project.slug}: #{cover}"
    end
  end

  it "keeps agency credits, not client language" do
    expect(Project.find("ntt-shotview").credit).to eq("Delivered for NTT DATA via LEX & Pulse Group")
    expect(Project.find("changeflow").credit).to be_nil
  end
end
```

- [ ] **Step 3: Run it**

Run: `bundle exec rspec spec/models/project_content_spec.rb`
Expected: 3 examples, 0 failures. If a cover path fails, fix the front-matter to match the real filename (note `team-gb` and one `changeflow` gallery item are `.jpeg`).

- [ ] **Step 4: Commit**

```bash
git add content/projects/ spec/models/project_content_spec.rb
git commit -m "content: add 8 placeholder project files with real media"
```

---

## Task 6: Work page (portfolio at /)

**Files:**
- Create: `app/controllers/pages_controller.rb`
- Modify: `config/routes.rb`
- Create: `app/views/pages/home.html.erb`, `app/views/pages/_project.html.erb`
- Test: `spec/requests/work_page_spec.rb`

**Interfaces:**
- Consumes: `Project.all` (Task 3), nav/footer (Task 4).
- Produces: `GET /` rendering the split hero and one `_project` row per project, images alternating sides, quote in each, tech tags, credit line, and a gallery affordance (`data-controller="lightbox"`) only when `project.lightbox?`.

- [ ] **Step 1: Write the failing request test**

Create `spec/requests/work_page_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Work page" do
  it "renders the hero and a row per project with credit and quote" do
    get "/"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Selected work")
    expect(response.body).to include("ShotView, The Open")
    expect(response.body).to include("Delivered for NTT DATA via LEX &amp; Pulse Group")
    expect(response.body).to include("Placeholder testimonial")
  end

  it "adds the lightbox controller only to projects with extra media" do
    get "/"
    # ntt-shotview has gallery+video; count of lightbox mounts equals lightbox-eligible projects
    eligible = Project.all.count(&:lightbox?)
    expect(response.body.scan('data-controller="lightbox"').size).to eq(eligible)
  end
end
```

- [ ] **Step 2: Run it (fails)**

Run: `bundle exec rspec spec/requests/work_page_spec.rb`
Expected: FAIL (no root route / controller).

- [ ] **Step 3: Add the route**

In `config/routes.rb`, inside the `draw` block, add:

```ruby
root "pages#home"
```

- [ ] **Step 4: Add the controller**

Create `app/controllers/pages_controller.rb`:

```ruby
class PagesController < ApplicationController
  def home
    @projects = Project.all
  end
end
```

- [ ] **Step 5: Add the project row partial**

Create `app/views/pages/_project.html.erb`:

```erb
<%# alternate image side by index: even = image left, odd = image right %>
<article class="grid grid-cols-1 border-t border-line md:grid-cols-2">
  <div class="relative overflow-hidden <%= index.odd? ? "md:order-2" : "" %>"
       <%= project.lightbox? ? 'data-controller="lightbox"' : "" %>>
    <img src="<%= asset_media(project.cover) %>" alt="<%= project.title %>"
         class="h-full min-h-[460px] w-full object-cover transition duration-300 hover:scale-105 <%= project.lightbox? ? "cursor-zoom-in" : "" %>"
         <%= project.lightbox? ? 'data-lightbox-target="cover" data-action="click->lightbox#open"' : "" %>>
    <% if project.lightbox? %>
      <span class="absolute bottom-3.5 right-3.5 rounded-full bg-black/60 px-2.5 py-1.5 font-mono text-xs text-white backdrop-blur">
        &#9635; <%= project.gallery.size %> images<%= " &middot; video".html_safe if project.videos.any? %>
      </span>
      <template data-lightbox-target="data">
        <%= tag.div(nil, data: { images: ([project.cover] + project.gallery).to_json, videos: project.videos.to_json, title: project.title }) %>
      </template>
    <% end %>
  </div>
  <div class="flex flex-col justify-center px-10 py-11">
    <div class="text-[56px] font-bold leading-none tracking-tight text-[#f0e0d9]"><%= format("%02d", project.order) %></div>
    <h3 class="mb-3 mt-0.5 text-[29px] font-semibold tracking-tight"><%= project.title %></h3>
    <div class="prose-sm max-w-none text-[15px] leading-relaxed text-ink2"><%= project.body_html.html_safe %></div>
    <% if project.quote.present? %>
      <blockquote class="mt-5 border-l-2 border-coral pl-4 text-[15px] italic text-ink">
        &ldquo;<%= project.quote %>&rdquo;
        <div class="mt-2 font-mono text-xs not-italic text-coral-d"><%= project.quote_author %></div>
      </blockquote>
    <% end %>
    <div class="mt-4 flex flex-wrap items-center gap-2">
      <% project.tech.each do |t| %>
        <span class="rounded border border-line px-2 py-0.5 font-mono text-[11px] text-ink2"><%= t %></span>
      <% end %>
      <span class="ml-auto font-mono text-[11px] text-muted"><%= [project.role, project.period].compact.join(" &middot; ").html_safe %></span>
    </div>
    <% if project.credit.present? %>
      <div class="mt-2 font-mono text-[11px] text-muted"><%= project.credit %></div>
    <% end %>
  </div>
</article>
```

Note: the quote author renders from `project.quote_author` (placeholder text in the content files until real copy lands). No em-dashes anywhere, including placeholders.

- [ ] **Step 6: Add the home view**

Create `app/views/pages/home.html.erb`:

```erb
<section class="grid grid-cols-1 items-end border-b border-line md:grid-cols-2">
  <div class="px-10 pb-12 pt-16">
    <div class="font-mono text-[11px] uppercase tracking-widest text-coral-d">Software engineer &middot; creative technologist</div>
    <h1 class="mt-3.5 max-w-[22ch] text-[50px] font-medium leading-[1.03] tracking-tight">I build the software behind brand activations people remember.</h1>
  </div>
  <div class="px-10 pb-12 pt-16">
    <p class="max-w-[46ch] font-body text-base leading-relaxed text-ink2">15 years shipping web apps, native apps and interactive installations, usually the technical lead turning a big creative idea into something that actually runs at scale, on time, in the wild.</p>
    <div class="mt-4 flex items-center gap-2 font-mono text-[11px] text-avail">
      <span class="inline-block h-1.5 w-1.5 rounded-full bg-avail shadow-[0_0_0_3px_rgba(21,154,91,0.18)]"></span>AVAILABLE FOR WORK
    </div>
  </div>
</section>

<div class="flex items-baseline justify-between px-10 pb-1 pt-8">
  <span class="font-mono text-xs uppercase tracking-widest text-coral-d">// Selected work</span>
  <span class="font-mono text-xs uppercase tracking-widest text-muted"><%= @projects.size %> projects</span>
</div>

<% @projects.each_with_index do |project, index| %>
  <%= render "project", project: project, index: index %>
<% end %>
```

- [ ] **Step 7: Add the `asset_media` helper**

In `app/helpers/application_helper.rb`, add:

```ruby
module ApplicationHelper
  # Media lives in public/media and is referenced by its path after public/media/.
  def asset_media(path)
    "/media/#{path}"
  end
end
```

- [ ] **Step 8: Run it (passes)**

Run: `bundle exec rspec spec/requests/work_page_spec.rb`
Expected: 2 examples, 0 failures.

- [ ] **Step 9: Eyeball it**

Run: `bin/dev` and open `http://localhost:3000`. Confirm: split hero, alternating project images (left/right/left…), quote + tags + credit in each, gallery badge on eligible ones. Stop the server.

- [ ] **Step 10: Commit**

```bash
git add app/controllers/pages_controller.rb config/routes.rb app/views/pages/ app/helpers/application_helper.rb spec/requests/work_page_spec.rb
git commit -m "feat: render the Work page from file-based projects"
```

---

## Task 7: Hand-rolled lightbox (Stimulus)

**Files:**
- Create: `app/javascript/controllers/lightbox_controller.js`
- Modify: `app/javascript/controllers/index.js` (register, if not eager-loaded)
- Test: `spec/system/lightbox_spec.rb`

**Interfaces:**
- Consumes: the `data-controller="lightbox"`, `data-lightbox-target="cover"`, and `data-lightbox-target="data"` `<template>` emitted in Task 6.
- Produces: a dark full-screen overlay opened on cover click, with prev/next, a thumbnail film-strip, a counter, project title, close on Esc/backdrop/✕, body scroll lock, focus return. Images and an optional video slide.

- [ ] **Step 1: Write the failing system test**

Create `spec/system/lightbox_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Lightbox", type: :system do
  before { driven_by(:selenium_chrome_headless) }

  it "opens on cover click and closes on Escape" do
    visit "/"
    first('[data-controller="lightbox"] [data-lightbox-target="cover"]').click
    expect(page).to have_css(".lightbox-overlay", visible: :visible)
    expect(page).to have_css(".lightbox-counter")
    find("body").send_keys(:escape)
    expect(page).to have_no_css(".lightbox-overlay")
  end
end
```

- [ ] **Step 2: Run it (fails)**

Run: `bundle exec rspec spec/system/lightbox_spec.rb`
Expected: FAIL (no overlay appears).

- [ ] **Step 3: Implement the controller**

Create `app/javascript/controllers/lightbox_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

// Dark immersive gallery. Reads image paths, an optional video URL and the title
// from a <template data-lightbox-target="data"> child, builds an overlay on demand.
export default class extends Controller {
  static targets = ["data"]

  connect() {
    const div = this.dataTarget.content.firstElementChild.dataset
    this.images = JSON.parse(div.images).map((p) => `/media/${p}`)
    this.videos = JSON.parse(div.videos || "[]")
    this.title = div.title || ""
    this.index = 0
    this.onKey = this.onKey.bind(this)
  }

  open() {
    this.index = 0
    this.overlay = this.build()
    document.body.appendChild(this.overlay)
    document.body.style.overflow = "hidden"
    document.addEventListener("keydown", this.onKey)
    this.trigger = document.activeElement
    this.overlay.querySelector(".lightbox-close").focus()
  }

  close() {
    if (!this.overlay) return
    this.overlay.remove()
    this.overlay = null
    document.body.style.overflow = ""
    document.removeEventListener("keydown", this.onKey)
    if (this.trigger) this.trigger.focus()
  }

  onKey(e) {
    if (e.key === "Escape") this.close()
    if (e.key === "ArrowRight") this.go(1)
    if (e.key === "ArrowLeft") this.go(-1)
  }

  go(delta) {
    const total = this.slides().length
    this.index = (this.index + delta + total) % total
    this.paint()
  }

  slides() {
    const s = this.images.map((src) => ({ type: "image", src }))
    this.videos.forEach((src) => s.push({ type: "video", src }))
    return s
  }

  paint() {
    const slide = this.slides()[this.index]
    const stage = this.overlay.querySelector(".lightbox-stage-media")
    stage.innerHTML =
      slide.type === "video"
        ? `<iframe class="lightbox-video" src="${this.embed(slide.src)}" allow="autoplay; fullscreen" allowfullscreen></iframe>`
        : `<img class="lightbox-img" src="${slide.src}" alt="">`
    this.overlay.querySelector(".lightbox-counter").textContent =
      `${String(this.index + 1).padStart(2, "0")} / ${String(this.slides().length).padStart(2, "0")}`
    this.overlay.querySelectorAll(".lightbox-thumb").forEach((t, i) =>
      t.classList.toggle("is-active", i === this.index)
    )
  }

  embed(url) {
    const yt = url.match(/[?&]v=([^&]+)/) || url.match(/youtu\.be\/([^?]+)/)
    if (yt) return `https://www.youtube.com/embed/${yt[1]}`
    const vim = url.match(/vimeo\.com\/(\d+)/)
    if (vim) return `https://player.vimeo.com/video/${vim[1]}`
    return url
  }

  build() {
    const el = document.createElement("div")
    el.className = "lightbox-overlay"
    el.innerHTML = `
      <div class="lightbox-top">
        <div class="lightbox-meta"><span class="lightbox-counter"></span> <span>${this.title}</span></div>
        <button class="lightbox-close" aria-label="Close">&#10005;</button>
      </div>
      <div class="lightbox-stage">
        <button class="lightbox-arrow lightbox-prev" aria-label="Previous">&#8249;</button>
        <div class="lightbox-stage-media"></div>
        <button class="lightbox-arrow lightbox-next" aria-label="Next">&#8250;</button>
      </div>
      <div class="lightbox-film">${this.slides()
        .map(
          (s, i) =>
            `<button class="lightbox-thumb" data-i="${i}">${
              s.type === "video" ? "<span class='lightbox-play'>&#9654;</span>" : ""
            }<img src="${s.type === "image" ? s.src : this.images[0]}" alt=""></button>`
        )
        .join("")}</div>`
    el.querySelector(".lightbox-close").addEventListener("click", () => this.close())
    el.querySelector(".lightbox-prev").addEventListener("click", () => this.go(-1))
    el.querySelector(".lightbox-next").addEventListener("click", () => this.go(1))
    el.addEventListener("click", (e) => { if (e.target === el) this.close() })
    el.querySelectorAll(".lightbox-thumb").forEach((t) =>
      t.addEventListener("click", () => { this.index = Number(t.dataset.i); this.paint() })
    )
    setTimeout(() => this.paint(), 0)
    return el
  }
}
```

- [ ] **Step 4: Ensure the controller is registered**

If `app/javascript/controllers/index.js` uses `eagerLoadControllersFrom`, nothing to do. Otherwise add:

```javascript
import LightboxController from "./lightbox_controller"
application.register("lightbox", LightboxController)
```

- [ ] **Step 5: Add lightbox styles**

Append to `app/assets/tailwind/application.css`:

```css
.lightbox-overlay{position:fixed;inset:0;z-index:50;display:flex;flex-direction:column;background:rgba(16,14,11,.94)}
.lightbox-top{display:flex;justify-content:space-between;align-items:center;padding:16px 22px;color:#efe9df}
.lightbox-meta{font-family:var(--font-mono);font-size:12px}
.lightbox-counter{color:var(--color-coral)}
.lightbox-close{width:34px;height:34px;border-radius:50%;background:rgba(255,255,255,.08);color:#efe9df;border:0;cursor:pointer}
.lightbox-stage{flex:1;position:relative;display:flex;align-items:center;justify-content:center;padding:0 60px}
.lightbox-img{max-width:100%;max-height:70vh;border-radius:8px;display:block}
.lightbox-video{width:min(90vw,1100px);aspect-ratio:16/9;border:0;border-radius:8px}
.lightbox-arrow{position:absolute;top:50%;transform:translateY(-50%);width:44px;height:44px;border-radius:50%;background:rgba(255,255,255,.09);color:#efe9df;border:0;font-size:20px;cursor:pointer}
.lightbox-prev{left:14px}.lightbox-next{right:14px}
.lightbox-film{display:flex;gap:8px;justify-content:center;padding:16px;flex-wrap:wrap}
.lightbox-thumb{width:64px;height:44px;border-radius:5px;overflow:hidden;opacity:.5;cursor:pointer;border:2px solid transparent;position:relative;padding:0;background:none}
.lightbox-thumb img{width:100%;height:100%;object-fit:cover}
.lightbox-thumb.is-active{opacity:1;border-color:var(--color-coral)}
.lightbox-play{position:absolute;inset:0;display:flex;align-items:center;justify-content:center;color:#fff;background:rgba(0,0,0,.35);font-size:12px}
```

- [ ] **Step 6: Run it (passes)**

Run: `bundle exec rspec spec/system/lightbox_spec.rb`
Expected: PASS (overlay opens, Escape closes). If Chrome is unavailable in CI, mark `spec/system` to run locally only, but it must pass locally.

- [ ] **Step 7: Full suite + lint**

Run: `bundle exec rspec` then `bin/rubocop`
Expected: all green (fix any Rubocop offenses with `bin/rubocop -a`).

- [ ] **Step 8: Commit**

```bash
git add app/javascript/controllers/ app/assets/tailwind/application.css spec/system/lightbox_spec.rb
git commit -m "feat: hand-rolled dark lightbox gallery"
```

---

## Self-review notes (author)

- **Spec coverage:** content pipeline (T2), Project PORO + ordering + lightbox eligibility + credit (T3, T5), design tokens/nav/footer (T4), split hero + alternating rows + quote + tags + credit (T6), dark hand-rolled lightbox with keyboard/thumbs/video (T7). CV, blog, contact, RSS, SEO, deploy are explicitly out of scope for this plan (plans 2 to 4).
- **Placeholders:** project *content* is intentionally placeholder per the user's decision; every *code* step contains complete code. The one visible UI placeholder marker (quote author) is called out and replaced with "Placeholder author" text, no em-dash.
- **Type consistency:** `Project#lightbox?`, `#credit`, `#gallery`, `#videos`, `#cover` are defined in T3 and consumed unchanged in T5/T6/T7; `asset_media`/`/media/` path scheme is consistent between the view (T6) and the JS controller (T7). `videos` is always an Array; the reader also accepts a legacy singular `video:` key and ignores blank values.
