# Content guide, steveb.io

Everything on the site is a file in this repo. To publish or edit, change a file
and deploy. No admin, no database. This guide is your checklist for gathering the
real content before the build.

**House style:** no em-dashes (use commas, colons, or hyphens). British spelling.
Lead with the engineering.

---

## 1. Portfolio projects  →  `content/projects/*.md`

One markdown file per project. Filename becomes the slug (`aurora-launch.md` →
`aurora-launch`). Copy `content/projects/_TEMPLATE.md` for each.

Front-matter fields:

| field          | required | notes |
|----------------|----------|-------|
| `title`        | yes | Project name |
| `role`         | yes | e.g. "Tech lead", "iOS lead" |
| `year`         | yes | e.g. 2025 |
| `order`        | yes | sort order, lower shows first |
| `tech`         | yes | list of tags, e.g. `[Rails, Hotwire, Metal]` |
| `cover`        | yes | the row image (path under `public/media/`) |
| `gallery`      | no  | list of image paths; presence adds the lightbox + badge |
| `video`        | no  | Vimeo/YouTube URL, or a committed file path |
| `quote`        | recommended | one testimonial line |
| `quote_author` | with quote | "Name, Role, Company" |

Body (after the `---`): the writeup in markdown.

**Per-project intake checklist (fill one per project):**
- [ ] Title, role, year
- [ ] Tech stack (the tags)
- [ ] 1 to 3 short paragraphs: the problem, what you built, the outcome/metric
- [ ] Cover image
- [ ] Extra gallery images and/or a video link (optional)
- [ ] A testimonial + who said it (optional but strong)

Suggested first set: Aurora, Meridian, Nimbus, Vantage, Halo (the mockup names are
placeholders, swap in your real projects).

---

## 2. Blog posts  →  `content/posts/*.md`

One file per post. Copy `content/posts/_TEMPLATE.md`. Filenames like
`2026-06-12-sqlite-in-production.md` are tidy but the `date` field is what sorts.

Fields: `title, date, author (defaults to you), tags, excerpt, thumbnail, cover`.
Body is markdown with headings, lists, pull quotes (`>`) and fenced code blocks
(syntax-highlighted). Reading time is calculated automatically.

You do not need posts to launch; even one is fine. Add more any time.

---

## 3. CV  →  `content/cv.yml`  (already drafted from your CV)

`content/cv.yml` is filled in with your real experience. Two TODOs remain:
- [ ] `github:` set your GitHub URL
- [ ] `content/cv.pdf`: drop your hand-made PDF here (the Download button links to it)

The "Copy for AI" button generates a clean markdown version from this file.

---

## 4. Media  →  `public/media/...`

Commit images/video here; reference them from front-matter by the path after
`public/` (so `public/media/projects/aurora/cover.jpg` → `projects/aurora/cover.jpg`).

Layout:
```
public/media/
  projects/<slug>/cover.jpg, 1.jpg, 2.jpg, ...
  posts/<slug>/thumb.jpg, hero.jpg
```

Recommended sizes (JPEG or WebP, compressed):
- Project cover: landscape, about 1600 x 1200.
- Gallery images: about 1600px on the long edge.
- Blog thumbnail: about 800 x 500. Blog hero: about 2000 x 1000.
- Video: prefer a Vimeo/YouTube link. If self-hosting, keep the file small.

Add descriptive `alt` text where the schema asks (accessibility + SEO).

---

## 5. Config bits to collect

- [ ] **Web3Forms access key** for the contact form (free, no account needed:
      web3forms.com, you get a key by email).
- [ ] **GitHub URL** (for the CV and footer icons).
- [ ] Confirm the public **email** is `steve@steveb.io` everywhere.

---

When these are gathered, the build drops them straight in with no code changes.
Design reference: `docs/design-mockups/` and `docs/superpowers/specs/2026-07-02-portfolio-design.md`.
