# Where should coding standards live for Claude Code: Skills vs CLAUDE.md/AGENTS.md vs reference docs

> **Saved to** `docs/research/coding-standards-placement.md`.
> **Why here:** the repo already has a `docs/` directory (holding `CONTENT-GUIDE.md`, `design-mockups/`, `superpowers/`) but no `notes/` or `research/` convention. A dedicated `docs/research/` subtree keeps investigation writeups out of the way of the product-facing content guide while staying discoverable in-repo.
>
> **Research date:** 2026-07-09. Facts are cited inline. PRIMARY = first-party Anthropic docs / the Agent Skills standard. SECONDARY = community write-ups (used only for framing, never for load-bearing facts).

---

## Executive answer (read this first)

The idiomatic consensus, confirmed directly by Anthropic's own docs, is: **put always-relevant, terse coding standards in the always-loaded memory file (CLAUDE.md / AGENTS.md), and reserve Skills for larger reference material or multi-step procedures that only *some* tasks need.** Anthropic states the split almost verbatim: "Put it in CLAUDE.md if Claude should always know it: coding conventions... Put it in a skill if it's reference material Claude needs sometimes (API docs, style guides)," and gives the exact pattern "CLAUDE.md says 'follow our API conventions,' a skill contains the full API style guide" [PRIMARY: features-overview]. The design axis is loading cost: CLAUDE.md/AGENTS.md loads **in full into every session** (a permanent context tax), whereas a Skill's body loads **only when its description matches the task** (progressive disclosure), costing roughly ~100 tokens of always-on metadata per skill [PRIMARY: memory, skills-overview]. For your four standards-skills, that means the rules you want to shape *every* edit (naming, where-logic-goes, the 37signals "no service objects" law, the deep-modules instinct) belong collapsed into a single lean `coding-standards.md` that AGENTS.md pulls in, while only genuinely *procedural, on-demand playbooks* (a step-by-step refactoring workflow you invoke deliberately) earn standalone skill status. Four overlapping standards-skills is indeed an anti-pattern, because Anthropic warns that when skill descriptions "are vague or overlap, Claude may load the wrong skill or miss one that would help" [PRIMARY: features-overview] — exactly your trigger-overlap problem when several fire on "refactor."

---

## 1. What each mechanism is FOR (Anthropic's official guidance)

Anthropic's "Extend Claude Code" overview is the authoritative decision table. It frames three relevant layers [PRIMARY: features-overview]:

| Feature | What it does | When to use it |
| --- | --- | --- |
| **CLAUDE.md** | Persistent context loaded every conversation | Project conventions, "always do X" rules |
| **Skill** | Instructions, knowledge, and workflows Claude can use | Reusable content, reference docs, repeatable tasks |
| **`.claude/rules/`** | Loaded every session, or only when matching files are opened | Language-specific or directory-specific guidelines |

The direct "CLAUDE.md vs Skill" comparison in the same doc resolves the standards question explicitly [PRIMARY: features-overview]:

- **"Put it in CLAUDE.md** if Claude should always know it: coding conventions, build commands, project structure, 'never do X' rules."
- **"Put it in a skill** if it's reference material Claude needs sometimes (API docs, style guides) or a workflow you trigger with `/<name>` (deploy, review, release)."
- **"Rule of thumb: Keep CLAUDE.md under 200 lines. If it's growing, move reference content to skills or split into `.claude/rules/` files."**

The memory doc reinforces this from the CLAUDE.md side: use CLAUDE.md for "Coding standards, workflows, project architecture" and "'always do X' rules"; but "If an entry is a multi-step procedure or only matters for one part of the codebase, move it to a skill or a path-scoped rule instead" [PRIMARY: memory].

**On AGENTS.md specifically (confirmed from primary docs):** Claude Code does **not** read `AGENTS.md` directly — "Claude Code reads `CLAUDE.md`, not `AGENTS.md`." The supported pattern is a `CLAUDE.md` that imports it: `@AGENTS.md`, optionally with Claude-specific instructions appended below. A symlink (`ln -s AGENTS.md CLAUDE.md`) also works [PRIMARY: memory]. This repo already does exactly this — `CLAUDE.md` is a 10-byte file containing `@AGENTS.md` — so AGENTS.md **is** the always-loaded memory file here, and everything said about CLAUDE.md applies to it.

The Skills overview states the purpose of a Skill: "reusable, filesystem-based resources that provide Claude with domain-specific expertise: workflows, context, and best practices that transform general-purpose agents into specialists," which "load on-demand" [PRIMARY: skills-overview].

---

## 2. Always-loaded context vs progressive disclosure (the core mechanic)

This is the axis everything hinges on.

**CLAUDE.md / AGENTS.md are always loaded, in full.** "CLAUDE.md files are loaded into the context window at the start of every session, consuming tokens alongside your conversation" [PRIMARY: memory]. Both memory systems "are loaded at the start of every conversation" [PRIMARY: memory]. Critically, "CLAUDE.md files are loaded in full regardless of length, though shorter files produce better adherence" [PRIMARY: memory]. Hence the ≤200-line target: "Files over 200 lines consume more context and may reduce adherence" [PRIMARY: memory]. Note the compounding cost beyond tokens: an over-long always-loaded file **reduces how reliably Claude follows any single rule in it**.

**@-imports do NOT reduce this cost.** A subtle but decisive point for your "reference tree that branches out" idea: "Splitting into `@path` imports helps organization but does not reduce context, since imported files load at launch" [PRIMARY: memory]. So a `coding-standards.md` pulled in via `@` from AGENTS.md is *still fully loaded every session* — it is a permanent tax, just a tidier one. Branching via `@`-imports buys maintainability, not context savings.

**Skills use progressive disclosure — three levels, loaded at different times** [PRIMARY: skills-overview]:

| Level | When loaded | Token cost | Content |
| --- | --- | --- | --- |
| 1. Metadata (`name` + `description`) | Always, at startup | ~100 tokens per skill | YAML frontmatter |
| 2. Instructions (SKILL.md body) | When the skill is triggered | Under 5k tokens | Main procedural guidance |
| 3. Resources (bundled files) | As needed, on demand | Effectively unlimited | Reference files, scripts, data |

"Claude loads this metadata at startup and includes it in the system prompt. This lightweight approach means you can install many Skills without context penalty; Claude only knows each Skill exists and when to use it" [PRIMARY: skills-overview]. "When you request something that matches a Skill's description, Claude reads SKILL.md from the filesystem via bash. Only then does this content enter the context window" [PRIMARY: skills-overview].

**Hard limits / recommended sizes (from primary docs):**
- `name`: max **64 characters**, lowercase/numbers/hyphens only [PRIMARY: skills-overview, best-practices].
- `description`: max **1024 characters**, non-empty, third-person; "critical for skill selection: Claude uses it to choose the right Skill from potentially 100+ available Skills" [PRIMARY: best-practices].
- SKILL.md body: keep **under 500 lines** / **under ~5k tokens** for optimal performance; split into referenced files past that [PRIMARY: best-practices, skills-overview].
- CLAUDE.md: target **under 200 lines** [PRIMARY: memory].
- Auto-memory `MEMORY.md`: only first 200 lines / 25KB loaded at start [PRIMARY: memory].

**How this maps to coding standards:** a standard is either something that should shape *every* edit (then the always-loaded file earns its cost, and terseness is a feature) or a bulky/situational procedure only *some* tasks need (then a skill's progressive disclosure earns its keep by staying out of context until triggered). The Anthropic-endorsed hybrid: "CLAUDE.md holds always-on rules; skills hold reference material loaded on demand" — literally "CLAUDE.md says 'follow our API conventions,' a skill contains the full API style guide" [PRIMARY: features-overview].

---

## 3. The AGENTS.md convention and the lean-root / branching-docs pattern

**The standard.** `AGENTS.md` is "a dedicated, predictable place to provide the context and instructions to help AI coding agents work on your project," complementing README.md with "extra, sometimes detailed context coding agents need: build steps, tests, and conventions" [PRIMARY: agents.md]. It is plain Markdown with no fixed schema: "Use any headings you like; the agent simply parses the text you provide" [PRIMARY: agents.md]. Recommended sections include a project overview, build/test commands, **code style guidelines**, testing instructions, and security considerations [PRIMARY: agents.md].

**Nesting / precedence.** "Agents automatically read the nearest file in the directory tree, so the closest one takes precedence and every subproject can ship tailored instructions" [PRIMARY: agents.md]. Claude Code implements the same walk-up-and-concatenate behavior for CLAUDE.md, "ordered from the filesystem root down to your working directory," closest-wins on conflict [PRIMARY: memory].

**Does the spec mandate a lean root that links out?** Not explicitly. The agents.md site "doesn't explicitly recommend a lean root file referencing deeper docs" and "doesn't prescribe linking to external documentation" [PRIMARY: agents.md]. So "lean root + branching reference tree" is a **community-emergent best practice**, not part of the formal spec [SECONDARY: buildbetter, morphllm]. Where it *is* first-party is inside the two Claude Code mechanisms that support scoping:

1. **`.claude/rules/` with `paths:` frontmatter** — the officially supported way to keep the root lean: "Rules with `paths` frontmatter only load when Claude works with matching files, saving context" [PRIMARY: memory, features-overview]. A rule scoped to `**/*.rb` only enters context when Claude touches Ruby.
2. **Skills' progressive-disclosure file tree** — SKILL.md as a table of contents that links one level deep to reference files loaded on demand [PRIMARY: best-practices].

**Caveat that kills naive branching in the memory file:** as established above, `@`-imports from CLAUDE.md/AGENTS.md load at launch regardless [PRIMARY: memory]. So a `coding-standards.md` reference tree hung off AGENTS.md via `@` is organizationally clean but **not** context-cheap — every branch loads every session. Only `.claude/rules/` (path-scoped) or Skills (description-triggered) actually defer loading. This is the single most important nuance for your situation.

---

## 4. Standards-as-skills vs standards-as-docs: consensus and tradeoffs

**Where Anthropic lands.** The primary guidance treats "style guides" as the canonical *skill* example — but pairs it with an always-on CLAUDE.md pointer. The endorsed division of labour: the terse directive ("follow our conventions," "no service objects," "prefer deep modules") lives always-on; the *full* style guide, if it is large, lives in a skill that loads when relevant [PRIMARY: features-overview]. Skills are explicitly described as being either "reference" (knowledge Claude uses throughout a session, like an API style guide) or "action" (a workflow you trigger like `/deploy`) [PRIMARY: features-overview].

**Token / context-budget tradeoff.**
- Every line in AGENTS.md is paid on *every* request, and past ~200 lines it also *degrades adherence* to the rules themselves [PRIMARY: memory].
- Every skill costs ~100 tokens of always-on metadata even when unused, but its body is free until triggered [PRIMARY: skills-overview]. Four standards-skills = ~400 tokens of permanent metadata plus four descriptions competing to match the same coding tasks.
- Anthropic's authoring principle: "The context window is a public good... being concise in SKILL.md still matters: once Claude loads it, every token competes with conversation history and other context" [PRIMARY: best-practices].

**The trigger-overlap / "which skill wins" problem (your exact pain).** This is documented as a real failure mode. "Claude matches your task against skill descriptions to decide which are relevant. **If descriptions are vague or overlap, Claude may load the wrong skill or miss one that would help.**" [PRIMARY: features-overview]. And skills **override by name, not by merge** — "when the same name exists at multiple levels, one definition wins based on priority (managed > user > project for skills)" [PRIMARY: features-overview]. But that only de-duplicates *identically named* skills; four *differently* named standards-skills (`sandi-metz-rules`, `deep-modules`, `codebase-design`, `37signals-style`) do **not** override each other — they compete on description match. When a task says "refactor this class," several of their descriptions match simultaneously. Claude may load one, some, or none, non-deterministically. Anthropic's mitigation is to make descriptions specific and non-overlapping [PRIMARY: best-practices] — but four skills carved from one cohesive philosophy (OO design / where code lives) are *inherently* overlapping, which is the structural smell. The consolidation fix (one always-on standards doc) removes the competition entirely because the rules are simply always present, not selected.

Your own skills' descriptions demonstrate the overlap concretely: `deep-modules` triggers on "refactor," "clean this up," "should I split this," code review, and "explicitly says it 'Complements sandi-metz-rules'"; `codebase-design` triggers on "improve a module's interface," "refactor," design decisions; `sandi-metz-rules` triggers on "refactoring," "code review," "code-quality passes." Three of four fire on a bare "refactor."

**Community consensus (SECONDARY, framing only).** Practitioner guides converge on the same shape: a thin root instruction file plus deeper docs pulled in on demand, keeping the root focused and letting detailed conventions load only when relevant [SECONDARY: buildbetter, augmentcode, morphllm]. This mirrors — and was arguably codified by — Anthropic's own `.claude/rules/` and Skills mechanisms, so treat these as corroboration, not independent authority.

---

## 5. Concrete recommendation for your four skills

Your four user-layer skills — `sandi-metz-rules`, `deep-modules`, `codebase-design`, `37signals-style` — are all **cross-cutting design philosophy that should shape every Ruby edit you make**, not situational procedures invoked on named tasks. By Anthropic's own test ("Put it in CLAUDE.md if Claude should always know it: coding conventions" [PRIMARY: features-overview]), most of this content wants to be **always-loaded standards, not skills.** Four skills is the wrong shape for three reasons, all documented above: (a) they overlap on triggers like "refactor," causing non-deterministic selection [PRIMARY: features-overview]; (b) as user-layer skills they only enter context *if* triggered, so a rule you want on *every* edit may silently not load; (c) they fragment one coherent philosophy across four competing descriptions.

**Recommended structure:**

1. **Collapse the always-relevant rules into one lean standards doc.** Create `coding-standards.md` (or a `.claude/rules/ruby.md` scoped to `**/*.rb` — see below) holding the *terse directives*: Sandi Metz's four size heuristics, the deep-modules instinct (narrow interface / substantial implementation; split to hide a concern, not on line count), the 37signals "no service objects / logic on the model / nouns not gerunds" laws, and the codebase-design seam vocabulary in its shortest actionable form. This is exactly the content that should shape every edit. Note your global `~/.claude/CLAUDE.md` already inlines much of this (the "Prefer Deep Modules" and "37signals Style" sections) — that duplication with the four skills is itself evidence the material wants to be always-on prose, not skills.

2. **How AGENTS.md should call it out.** Two valid options; pick per how big the standards doc gets:
   - **If it stays terse (≤ the 200-line budget across the whole file):** inline the standards directly into AGENTS.md under a "Coding standards" heading. Simplest; zero indirection. Your AGENTS.md already does this partially ("The Rails Way — where logic goes," "Prefer deep modules").
   - **If it is substantial:** keep AGENTS.md lean and either (a) `@coding-standards.md` import it — clean, but remember **it still loads every session** [PRIMARY: memory] — or, better for context economy, (b) move the Ruby-specific bulk into **`.claude/rules/ruby.md` with `paths: ["**/*.rb"]`**, which loads *only when Claude touches Ruby files* [PRIMARY: memory]. Option (b) is the only "branching" arrangement that actually saves context, and it fits a Rails repo perfectly since the standards are Ruby-scoped anyway.

3. **What (if anything) stays a skill.** Keep a skill *only* for genuinely procedural, deliberately-invoked playbooks — e.g. a `/refactor-plan` or `/deep-module-review` workflow with a multi-step checklist you run on demand, or a large worked-examples reference you don't want in context by default. That is the "repeatable task / reference material Claude needs sometimes" case Anthropic reserves skills for [PRIMARY: features-overview]. The *philosophy and rules* themselves do not need progressive disclosure — you want them applied unconditionally, which is the definition of always-loaded content. If you keep any as a skill, set `disable-model-invocation: true` so it costs zero context until you type `/<name>`, and so it never competes for auto-trigger [PRIMARY: features-overview].

4. **Kill the trigger overlap by construction.** Once the rules are always-on prose, there is no description-matching contest at all — no "which of my four skills wins on 'refactor'." That is the cleanest resolution of the problem, and it is precisely what Anthropic's "put always-known conventions in CLAUDE.md" guidance is optimizing for.

**Net:** collapse `sandi-metz-rules` + `deep-modules` + `codebase-design` + `37signals-style` into a single always-loaded Ruby coding-standards doc (inlined in AGENTS.md if terse, or `.claude/rules/ruby.md` path-scoped if bulky). Retain a skill only for any true step-by-step *procedure* you invoke deliberately, not for the standing rules themselves.

---

## Sources

### PRIMARY (first-party Anthropic docs + the Agent Skills standard)

- **features-overview** — "Extend Claude Code" (when to use CLAUDE.md vs Skills vs rules vs hooks; the "CLAUDE.md vs Skill" and "CLAUDE.md vs Rules vs Skills" comparison tables; trigger-overlap warning; context-cost-by-feature table): https://code.claude.com/docs/en/features-overview
- **memory** — "How Claude remembers your project" (CLAUDE.md loaded every session in full; ≤200-line target; `@`-imports load at launch and don't reduce context; `.claude/rules/` and `paths:` scoping; AGENTS.md handled via `@AGENTS.md` import / symlink; auto-memory): https://code.claude.com/docs/en/memory
- **skills-overview** — "Agent Skills" (three-level progressive disclosure; ~100 tokens metadata; <5k-token body; name ≤64 chars, description ≤1024 chars; Claude Code skill locations `~/.claude/skills/` and `.claude/skills/`): https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
- **best-practices** — "Skill authoring best practices" ("context window is a public good"; concise SKILL.md; ≤500-line body; specific non-overlapping descriptions; one-level-deep references; degrees of freedom): https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- **skills (Claude Code)** — "Extend Claude with skills" ("Create a skill when... a section of CLAUDE.md has grown into a procedure rather than a fact"; skill body loads only when used; follows the agentskills.io open standard): https://code.claude.com/docs/en/skills
- **agents.md** — the AGENTS.md open format (purpose; plain-Markdown/any-headings; nearest-file-wins nesting; recommended sections incl. code style; does not mandate lean-root-linking): https://agents.md/
- **Equipping agents for the real world with Agent Skills** — Anthropic engineering (progressive disclosure as core principle; "amount of context that can be bundled into a skill is effectively unbounded"): https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills

### SECONDARY (community practitioner write-ups — framing/corroboration only, not load-bearing)

- BuildBetter, "AGENTS.md Complete Guide for Engineering Teams (2026)" (thin-root + per-package files; reference deeper docs so they load only when relevant): https://blog.buildbetter.ai/agents-md-complete-guide-for-engineering-teams-in-2026/
- Augment Code, "How to Build Your AGENTS.md" (context-scoping, keep root focused): https://www.augmentcode.com/guides/how-to-build-agents-md
- Morph, "AGENTS.md Spec (2026): AGENTS.md vs CLAUDE.md vs .cursorrules": https://www.morphllm.com/agents-md-guide
- Firecrawl, "Agent Skills Explained: How SKILL.md Files Work" (progressive-disclosure token-budget framing): https://www.firecrawl.dev/blog/agent-skills
