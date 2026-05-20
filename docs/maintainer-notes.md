# Maintainer Notes

These notes were split out of `SKILL.md` so the executable skill protocol stays compact.


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
