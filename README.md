# tech-debt-audit

A Claude Code skill that produces a thorough, citable tech debt audit of your entire codebase — not a generic best-practices checklist.

```
/tech-debt-audit
```

That's the whole interface. Run it in any repo, get back `TECH_DEBT_AUDIT.md` with file-cited findings, severity, effort estimates, and a ranked list of what to actually fix.

## Why this exists

LLM-generated code reviews fail in a predictable way: they pattern-match against generic heuristics, surface obvious findings without grounding them in the actual code, and produce comprehensive-feeling output that nobody acts on. The result is a tab nobody opens twice.

This skill is opinionated about avoiding that failure mode. Three design choices do most of the work:

**Forced orientation before judgment.** The protocol requires the model to read the manifest, map the directory structure, analyze git churn, and write a mental model of the architecture *before* it forms any opinions. Phase 1 isn't optional. Findings without context are vibes.

**File:line citations on every finding.** A finding without a citation is unfalsifiable, and unfalsifiable findings don't get fixed. The skill rejects vague claims like "the code generally..." and requires `path/to/file.ext:LINE` on every concrete finding.

**A required "looks bad but is actually fine" section.** This is the single biggest separator between a real audit and a checklist regurgitation. Forcing the model to surface calls it considered making and chose not to is what catches shallow analysis. If that section comes back empty, the audit didn't look hard enough.

The skill also explicitly forbids recommending rewrites, forbids padding categories with filler, and produces a persistent artifact (`TECH_DEBT_AUDIT.md`) you can commit and track over time.

## Why not the built-in Claude Code skills?

Claude Code ships several skills that touch this space. None of them do what a debt audit needs to do.

| Built-in | What it does | Why it's not a debt audit |
|----------|--------------|----------------------------|
| `/review` | PR-style code review of changes | Diff-scoped. Useful before merging a branch, not useful when you've inherited 80k LOC and want to know what's rotten. |
| `/simplify` | Reduces over-engineered code in a specific area | Tactical, not architectural. Doesn't survey, doesn't cite, doesn't produce an artifact. |
| `/debug` | Targets a specific failure or unexpected behavior | Reactive. You point it at a known problem; an audit's job is to *find* the problems. |
| `/loop`, `/batch` | Workflow primitives for repeated or grouped tasks | Orchestration, not analysis. |

What this skill adds:

- **Whole-repo scope** across the nine dimensions that actually matter for debt: architectural decay, consistency rot, type & contract debt, test debt, dep & config debt, performance & resource hygiene, error handling & observability, security hygiene, and documentation drift.
- **Multi-tool grounding.** Detects the stack and runs the right tools when available — `npm audit`, `knip`, `madge`, `depcheck` for TS/JS; `pip-audit`, `ruff`, `vulture`, `pydeps` for Python; `cargo audit`, `cargo udeps`, `cargo machete` for Rust; `govulncheck`, `staticcheck`, `golangci-lint` for Go — and folds the findings into the report. Missing tools are noted instead of blocking the audit.
- **Subagent dispatch for large repos.** For codebases over ~50k LOC, the protocol parallelizes across modules so the main agent doesn't run out of context window before Phase 3.
- **Persistent, citable artifact.** `TECH_DEBT_AUDIT.md` lives in your repo. You can commit it, review it in PRs, link to specific findings.
- **Repeat-run mode.** On subsequent runs, resolved findings are marked `RESOLVED`, stale ones are updated, and new ones are tagged `NEW`. The audit becomes a living document.

## Installation

Personal install (available across all your projects):

```bash
mkdir -p ~/.claude/skills/tech-debt-audit
```

```bash
curl -o ~/.claude/skills/tech-debt-audit/SKILL.md https://raw.githubusercontent.com/ksimback/tech-debt-skill/main/SKILL.md
```

Project-only install (just this repo):

```bash
mkdir -p .claude/skills/tech-debt-audit
curl -o .claude/skills/tech-debt-audit/SKILL.md https://raw.githubusercontent.com/ksimback/tech-debt-skill/main/SKILL.md
```

Verify it's available:

```bash
echo "/skills" | claude | grep tech-debt-audit
```

## Usage

In Claude Code, in the repo you want audited:

```
/tech-debt-audit
```

That's it. Output goes to `TECH_DEBT_AUDIT.md` in the repo root. First run takes 5–20 minutes depending on repo size. Subsequent runs in repeat-run mode are faster because the existing audit is used as a baseline.

To audit only a specific subtree (useful for very large monorepos):

```
/tech-debt-audit src/payments
```

To get a mid-audit course correction (recommended on first run for any new codebase), interrupt after Phase 1 with:

> Before Phase 2, tell me what surprised you in Phase 1 and what you want to investigate that isn't in the dimensions list.

The best findings often come from things the prompt didn't anticipate.

## Fixture sanity check

This repo includes a tiny intentionally flawed fixture under `examples/toy-python-service`.

Use it to check that the skill:

- does not pad tiny repos to 30 findings,
- cites concrete `file:line` locations,
- catches obvious SQL string concatenation and hardcoded secret hygiene issues,
- includes a "looks bad but is actually fine" section.

The expected shape is documented in:

```text
examples/toy-python-service/TECH_DEBT_AUDIT.expected.md
```

To validate that the fixture line citations still match the sample app:

```powershell
pwsh scripts/validate-fixture.ps1
```

## How it works

Three phases:

1. **Orient** — read the manifest, map the structure, analyze `git log` for churn, identify the largest and most-modified files (their intersection is where debt usually hides), write a mental model.
2. **Audit** — sweep across nine dimensions using `rg`, `ast-grep`, and language-native tooling. Cite `file:line` on every finding.
3. **Deliverable** — write `TECH_DEBT_AUDIT.md` with executive summary, mental model, findings table, top-5 priorities, quick wins, the "looks bad but is fine" section, and open questions.

The full protocol is in [`SKILL.md`](./SKILL.md).

Maintainer and adaptation notes are in [`docs/maintainer-notes.md`](./docs/maintainer-notes.md).

## What the output looks like

`TECH_DEBT_AUDIT.md` has this shape:

```
## Executive summary
- 3 Critical findings, 12 High, 31 Medium, 18 Low
- Largest debt concentration: src/payments/* (3 of 3 Critical findings)
- ...

## Findings
| ID   | Category            | File:Line                       | Severity | Effort | Description | Recommendation |
| F001 | Architectural decay | src/payments/processor.ts:1240  | Critical | L      | 1,400-line god class handling routing, validation, retry, and reconciliation | Extract retry and reconciliation into separate services |
| ...

## Top 5
1. F001 — Decompose payments/processor.ts: ...

## Quick wins
- [ ] F042: Remove unused dep `lodash.merge` (replaced by native ...)
- [ ] ...

## Things that look bad but are actually fine
- The deeply nested callback pattern in src/legacy/webhooks.ts looks like a refactor target, but it preserves ordering guarantees the queue-based replacement would break. Leave it.
- ...

## Open questions for the maintainer
- Is src/experiments/ intentionally untested, or did it fall through?
- ...
```

## Customization

The skill is designed to be forked and adapted. Common modifications:

- **Add domain-specific dimensions.** The nine in Phase 2 are a starting point. Frontend repos can add accessibility; ML repos can add eval drift; LLM apps can add prompt versioning and tool-call cost; infra can add IaC drift.
- **Tune severity thresholds.** If your codebase has a higher baseline (e.g., god files defined as >800 LOC instead of >500), edit the dimension definitions directly.
- **Override per project.** A `.claude/skills/tech-debt-audit/SKILL.md` in a specific repo overrides the global one. Useful when one project needs custom dimensions the others don't.
- **Split into supporting files.** As `SKILL.md` grows, extract sections into sibling files (`severity-rubric.md`, `stack-tooling.md`) and reference them. Claude Code lazy-loads supporting files, keeping the main protocol tight.

## Limitations

This is a static audit, not a security audit. It catches obvious security hygiene issues (hardcoded secrets, SQL injection patterns, weak crypto) but won't replace a real pen test or threat model.

It won't catch business-logic bugs. Those require domain knowledge the model doesn't have.

It can't perfectly distinguish intentional simplicity from accidental simplicity. The "open questions" section exists for exactly this reason — when the skill is unsure, it asks rather than asserting.

For very large repos (>200k LOC), even subagent dispatch can produce shallow results. Scope to a module or run section-by-section.

## Contributing

PRs welcome. Before submitting:

1. Test against at least two real codebases of different stacks.
2. If you're adding a dimension, include a justification for why it isn't covered by the existing nine.
3. If you're tightening a rule, show a before/after audit excerpt demonstrating the improvement.

The single design constraint: this skill must produce findings that engineers act on. Anything that pushes toward "feels comprehensive but nothing changes" is a regression and will be rejected.

## License

MIT. Use it, fork it, ship it. Attribution appreciated but not required.

## Credits

Built on the [Claude Code Agent Skills](https://code.claude.com/docs/en/skills) standard.

Inspired by the experience of working with Claude Code on codebases that got really messy over time.

