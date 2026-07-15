---
name: cv-pdf
description: Generate a two-page, ATS-safe PDF CV from a Markdown copy draft. Use when asked to build, refresh or tailor a CV PDF, turn a content/_*_cv.md draft into a PDF, or tweak the CV print layout.
---

# CV PDF generation

Produces clean, two-page, ATS-readable A4 PDF CVs from HTML via headless
Chrome. Every version lives in `content/cvs/`, one HTML + PDF pair per
application, named by application (`nesta.html`, `nesta.pdf`). The site never
reads that directory, and past versions are kept: they are the raw material
for tailoring the next one.

## Workflow

1. **The HTML is the working file** — `content/cvs/<application>.html`. Start
   by copying the closest existing version in `content/cvs/` (base:
   `nesta.html`) and tailor the wording directly in the HTML; it is
   deliberately copy-editable (one bullet per `li`). Only fall back to
   `.claude/skills/cv-pdf/template.html` when starting a structurally
   different CV from scratch. Escape `&` as `&amp;`.
   Do not create new Markdown drafts: `content/cvs/nesta.md` is the original
   base copy, kept for reference, and is not maintained in step with the HTML.
   Never delete old versions; they might be useful.
2. Generate: `bin/cv-pdf content/cvs/<application>.html`
   Writes the PDF next to the HTML and **fails if the page count is not 2**
   (override with `--pages N`).
3. **Verify visually, always.** Render both pages and look at them:
   `pdftoppm -png -r 80 content/cvs/<application>.pdf /tmp/cv`
   then Read `/tmp/cv-1.png` and `/tmp/cv-2.png`. Check the checklist below.
4. Iterate the break and density (see below) until both pages look deliberate.

## The two-page break

The split must look intentional, never accidental.

- An explicit `<div class="page-break"></div>` between two `.job` articles
  decides where page 1 ends. Place it so page 1 ends flush at a natural
  boundary (after a complete role), never mid-entry.
- `.job { break-inside: avoid }` and `h2 { break-after: avoid }` are the safety
  net, not the mechanism. Do not rely on natural flow for the split.
- Tuning knobs, in order of preference: move the `.page-break`; adjust
  `body { font-size }` (9.3-10pt); adjust `section { margin-top }` and
  `.job { margin-bottom }`; trim copy (with the user, in the Markdown).
- Target: page 1 full to within ~2 lines of the bottom; page 2 at least
  two-thirds full. If the third page appears, `bin/cv-pdf` will fail loudly.

## ATS rules (why the template is the way it is)

Keep these invariants when editing the template or a filled CV:

- **Single column, top-to-bottom.** No tables, sidebars, text boxes or
  multi-column layout anywhere. Flexbox for the role/date line is fine because
  the DOM order (role then dates) is what parsers read.
- **Real text only.** No images, icons, logos, photos, charts or skill bars.
  Headless Chrome embeds a proper text layer; never rasterise.
- **Standard section headings**: Profile, Skills, Experience, Earlier Roles,
  Additional, Education. Parsers key on these words; do not get creative.
- **Reverse chronological** experience with one consistent date format:
  `2019 - 2023` / `2023 - Present`, plain hyphen, never an em-dash.
- **Contact details as visible text** near the top: location, email, site,
  GitHub, LinkedIn written out (URLs without scheme), not hidden behind links.
- **Common fonts** (Helvetica/Arial stack), body 9.3-10pt, standard round
  bullets. Keywords spelled out in Skills exactly as a job spec would.
- **Nothing in print headers/footers** (`--no-pdf-header-footer` is set); some
  parsers drop that region. No page numbers needed on two pages.
- Colour is safe for ATS (parsers read text, not style) so the cobalt accent
  stays, but only on the headline, section headings and rules.

## House style

- No em-dashes anywhere, in copy or markup. British spelling.
- Client brands were delivered *for* via agencies; phrase as "delivered for",
  never "clients".
- Only approved customer names (see global CLAUDE.md list); "Am Law 200" and
  similar generics are always safe.

## The site's own CV

`content/cv.pdf` (served at `/cv.pdf`) can be regenerated the same way: build
the copy from `content/cv.yml` (the `Cv` model's `to_markdown` shows the
canonical ordering), fill the template as `content/cvs/site.html`, and output
over `content/cv.pdf` with `bin/cv-pdf content/cvs/site.html content/cv.pdf`.
Confirm with the user before overwriting the served PDF.
