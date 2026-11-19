---
name: tech-debt-audit
description: Thorough, user-invoked tech debt and architecture audit of the current codebase. Produces TECH_DEBT_AUDIT.md with file-cited findings, severity, effort estimates, and a required "looks bad but is actually fine" section. Use when the user asks for a debt audit, codebase health check, architecture review, or code quality assessment of an entire repo. Does not auto-invoke.
disable-model-invocation: true
---

# Tech Debt Audit

A Claude Code skill that conducts a deliberate, opinionated audit of an entire codebase and produces `TECH_DEBT_AUDIT.md` with cited findings.

When invoked via `/tech-debt-audit`, follow the protocol below. Everything from here through the `---` divider is the protocol Claude executes. The section after the divider is documentation for humans installing or maintaining this skill.

---

## Operating principles

Find what's actually wrong. Not diplomatic. Not surface-only. Don't pattern-match to generic best practices without grounding in this specific repo. No sycophancy. No "overall the codebase is well-structured" filler.

Cite `file:line` for every concrete finding. Vague claims like "the code generally..." don't count. Read code before judging it — a pattern that looks wrong in isolation may be load-bearing.

## Phase 1: Orient

Do not skip this. Forming opinions before understanding the system produces bad audits.

1. Read the README, package manifest (`package.json` / `pyproject.toml` / `Cargo.toml` / `go.mod`), and any architecture docs in `/docs` or `/adr`.
2. Map the directory structure and identify the major modules / layers.
3. Run `git log --oneline -200` and `git log --stat --since="6 months ago"` to see what's actually changing and where churn concentrates.
4. Identify entry points, hot paths, and cold corners.
5. List the top 20 largest files by line count, and the 20 files most frequently modified in the last 6 months. The intersection is where debt usually hides.
6. Use `TodoWrite` to publish a plan so the user can see progress through the phases.

Write a 1–2 paragraph mental model of the architecture before proceeding. If your model contradicts the README, flag it — that itself is a finding.

## Phase 2: Audit across these dimensions

Use `rg`, `ast-grep`, and language-native tooling to find concrete examples. Cite `path/to/file.ext:LINE` for every finding.

1. **Architectural decay** — circular deps, layering violations, god files (>500 LOC) and god functions, duplicated logic across 3+ sites where an abstraction should exist, abstractions that exist but nobody uses, dead code (unused exports, unreachable branches, stale commented-out blocks).

   Also flag **reinvented wheels**: hand-rolled code for a solved problem (regex URL/email/date validation, custom slugify/debounce/retry/rate-limit/queue/JWT/query-string helpers) where the project already depends on a library that does it, the platform has a built-in, or a well-established library exists; and custom UI components that duplicate one the project's component library already ships (alerts, modals, selects, tooltips, pagination). Cite the custom code and name the replacement. Do not flag real domain logic.

2. **Consistency rot** — multiple ways of doing the same thing (HTTP clients, error handling, logging, config loading, validation, date handling). Naming drift. Folder structure that no longer reflects what the code actually does.

3. **Type & contract debt** — `any` / `unknown` / `as any` / `# type: ignore` / loose dicts. Untyped API boundaries. Missing schema validation at trust boundaries.

4. **Test debt** — run coverage if available; identify gaps on critical paths. Tests that assert implementation rather than behavior. Skipped or flaky tests. High-churn files with no tests.

5. **Dependency & config debt** — `npm audit` / `pip-audit` / `cargo audit` for CVEs. Unused deps. Duplicate deps doing the same job. Env var sprawl (referenced but not documented; defaults inconsistent across envs).

6. **Performance & resource hygiene** — N+1 queries, sync work in async paths, blocking I/O on hot paths, uncleaned listeners or handles, unnecessary serialization.

7. **Error handling & observability** — swallowed exceptions, blanket catches, errors logged but not handled, inconsistent error shapes across modules, missing structured logs on critical paths.

8. **Security hygiene** — hardcoded secrets, string-concat SQL, missing input validation at trust boundaries, permissive auth or CORS, weak crypto.

9. **Documentation drift** — README claims that don't match reality, comments that contradict adjacent code, public APIs without docstrings.

## Phase 3: Deliverable

Write to `TECH_DEBT_AUDIT.md` in the repo root with this structure:

- **Executive summary** — max 10 bullets, ranked by impact.
- **Architectural mental model** — your understanding of the system as it actually is.
- **Findings table** — columns: `ID | Category | File:Line | Severity (Critical/High/Medium/Low) | Effort (S/M/L) | Description | Recommendation`. Aim for 30–80 findings; padding past that is noise.
- **Top 5 "if you fix nothing else, fix these"** — with concrete diff sketches or refactor outlines, not vague advice.
- **Quick wins** — Low effort × Medium+ severity, as a checklist.
- **Things that look bad but are actually fine** — calls you considered flagging and chose not to, with reasoning. **This section is required.** If it's empty, you didn't look hard enough.
- **Open questions for the maintainer** — things you couldn't tell were debt vs. intentional.

## Rules

- Cite `file:line` for every concrete finding.
- If unsure whether something is debt or intentional, ask in the open questions section — don't assert.
- Don't recommend rewrites. Recommend specific, scoped changes.
- Don't pad. If a category has nothing material, write "Nothing material" and move on.
- No sycophancy. Tell the user what's broken.

## Stack-specific tooling

Detect the stack from the manifest and run the relevant tools. Run them in parallel when possible.

- **TypeScript / JavaScript** — `npm audit`, `npx knip` (dead exports), `npx madge --circular` (circular deps), `npx depcheck` (unused deps), `tsc --noEmit` for type drift.
- **Python** — `pip-audit`, `ruff check`, `vulture` (dead code), `pydeps --show-cycles`, `mypy --strict` for type drift.
- **Rust** — `cargo audit`, `cargo udeps`, `cargo machete`, `cargo clippy -- -W clippy::pedantic`.
- **Go** — `govulncheck`, `go vet`, `staticcheck`, `golangci-lint run`.

If a tool isn't installed, note it in the audit and move on rather than blocking. Do not install dev tools globally without permission.

## Large repos: spawn subagents

If the repo is >50k LOC or has >5 top-level modules, dispatch subagents (Task tool) in parallel — one per module — and synthesize their reports. Serial reading on a large repo eats the context window before findings can be written.

Each subagent gets: scope (one module), the dimensions list above, the citation requirement, and a 200-finding cap. The main agent merges, dedupes, and ranks.

## Repeat-run mode

If `TECH_DEBT_AUDIT.md` already exists in the repo, read it first. Mark resolved findings as `RESOLVED`, update stale ones, and tag new findings with `NEW`. This turns the audit into a living document tracked over time.

---

# Project documentation

Everything below is for humans installing, using, or contributing to this skill. It is not part of the audit protocol.

## Installation

Personal install (available across all your projects):

```bash
mkdir -p ~/.claude/skills/tech-debt-audit
```

```bash
curl -o ~/.claude/skills/tech-debt-audit/SKILL.md https://raw.githubusercontent.com/ksimback/tech-debt-skill/main/SKILL.md
```

Or for a project-only install (just this repo):

```bash
mkdir -p .claude/skills/tech-debt-audit && cp /path/to/SKILL.md .claude/skills/tech-debt-audit/SKILL.md
```

Verify it loaded:

```bash
echo "/skills" | claude
```

## Usage

In Claude Code, in the repo you want audited:

```
/tech-debt-audit
```

That's it. Output goes to `TECH_DEBT_AUDIT.md` in the repo root. First run takes 5–20 minutes depending on repo size; subsequent runs in repeat-run mode are faster.

## Philosophy

Most "code review" prompts produce a bulleted list of generic best-practice violations dressed up as findings. This skill is built to avoid that failure mode. Three design choices do most of the work:

**Forced orientation before judgment.** Phase 1 isn't optional decoration. Without a real mental model of the architecture, every Phase 2 finding is just pattern-matching against generic heuristics. Reading `git log` for churn data is what surfaces the files that *actually* have debt versus the files that just look messy.

**File:line citations on every finding.** This is the single biggest quality lever. A finding without a citation is a vibe. Vibes don't get fixed.

**The "looks bad but is actually fine" section is required.** This is the one most people remove when adapting the prompt. Don't. Forcing the model to surface the calls it considered making and chose not to is what separates a real audit from a checklist regurgitation. If that section is empty, the audit is shallow.

The skill also explicitly forbids recommending rewrites and forbids padding categories. Both are common LLM failure modes — rewriting is easier than diagnosing, and padding makes outputs feel thorough when they aren't.

## What you get

`TECH_DEBT_AUDIT.md` looks like this in shape:

```
# Tech Debt Audit — <repo name>
Generated: 2026-04-25

## Executive summary
- 3 Critical findings, 12 High, 31 Medium, 18 Low
- Largest debt concentration: src/payments/* (god module, 4 of 3 Critical findings)
- ...

## Architectural mental model
The system is a [...]

## Findings
| ID | Category | File:Line | Severity | Effort | Description | Recommendation |
|----|----------|-----------|----------|--------|-------------|----------------|
| F001 | Architectural decay | src/payments/processor.ts:1240 | Critical | L | 1,400-line god class handling routing, validation, retry, and reconciliation | Extract retry and reconciliation into separate services |
| ... |

## Top 5
1. **F001 — Decompose payments/processor.ts** ...

## Quick wins
- [ ] F042: Remove unused dep `lodash.merge` (replaced by native ...)
- [ ] ...

## Things that look bad but are actually fine
- The deeply nested callback pattern in `src/legacy/webhooks.ts` looks like a refactor target, but it preserves ordering guarantees that the queue-based replacement would break. Leave it.
- ...

## Open questions
- Is `src/experiments/` intentionally untested, or did it fall through?
- ...
```

## Adaptation notes

**Project-level overrides.** A `.claude/skills/tech-debt-audit/SKILL.md` in a specific repo overrides the global one. Useful when a project needs custom dimensions — e.g., an agent codebase might add "prompt injection surface area" or "tool-call cost per turn" as audit categories.

**Mid-audit course correction.** After Phase 1 completes, you can interrupt with: *"Before Phase 2, tell me what surprised you in Phase 1 and what you want to investigate that isn't in the dimensions list."* The best findings often come from things the prompt didn't anticipate. Worth doing on first run for any new codebase.

**Tuning severity calibration.** If the model is over- or under-flagging, edit the Phase 2 dimensions list to add explicit thresholds. Example: change "god files (>500 LOC)" to ">800 LOC" if your codebase has a higher baseline.

**Adding categories.** The 9 dimensions in Phase 2 are a starting point. Add domain-specific ones for your stack — accessibility for frontend, IaC drift for infra, model evals for ML, prompt versioning for LLM apps.

**Splitting into supporting files.** As this SKILL.md grows, you can extract sections into sibling files (`severity-rubric.md`, `stack-tooling.md`) and reference them from the protocol. Claude Code lazy-loads them only when needed.

## Limitations

This is a static audit, not a security audit. It catches obvious security hygiene issues (hardcoded secrets, SQL injection patterns) but won't replace a real pen test or threat model.

It won't catch business-logic bugs. Those require domain knowledge the model doesn't have.

It can't tell intentional simplicity from accidental simplicity. The "open questions" section exists for exactly this reason — when in doubt, the skill asks rather than assuming.

For very large repos (>200k LOC), even subagent dispatch can produce shallow results. Consider scoping to a module: `/tech-debt-audit src/payments`.

## Contributing

PRs welcome. Before submitting:

1. Test against at least two real codebases of different stacks.
2. If you're adding a dimension, include a justification for why it isn't covered by the existing 9.
3. If you're tightening a rule, show a before/after audit excerpt demonstrating the improvement.

The single design constraint: this skill must produce findings that engineers act on. Anything that pushes toward "feels comprehensive but nothing changes" is a regression.

## License

MIT. Use it, fork it, ship it. Attribution appreciated but not required.

## Credits

Built on the Claude Code Agent Skills standard. Inspired by the experience of working with Claude Code on codebases that got really messy over time.
