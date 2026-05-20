# Tech Debt Audit — tech-debt-skill

Generated: 2026-05-19

## Executive summary

- No Critical findings. This repository is a small documentation/protocol repo, not an application codebase.
- RESOLVED: The main debt was portability. The protocol now includes host-runtime fallbacks, lightweight metadata, and maintainer docs separated from the executable skill body.
- RESOLVED: The protocol previously referenced Claude-specific runtime primitives (`TodoWrite`, `Task tool`) without fallbacks. It now includes host-runtime fallback language.
- RESOLVED: Installation and verification instructions previously diverged between `README.md` and `SKILL.md`; the README now matches the `SKILL.md` command style.
- RESOLVED: The audit protocol previously demanded 30–80 findings without qualifying repo size; it now limits that target to substantial repos.
- RESOLVED: Stack-specific tooling is listed, and the repo now has a tiny fixture plus a validation script to keep expected line citations aligned.
- RESOLVED: The repo previously lacked an example fixture. It now includes `examples/toy-python-service` plus an expected audit shape.

## Architectural mental model

This repository contains a single Claude Code skill distributed as `SKILL.md`, plus a human-facing `README.md`. There is no executable product code, package manifest, test suite, or runtime dependency graph. The "architecture" is therefore mostly a documentation boundary: the top half of `SKILL.md` is the model-executed protocol, and the lower half is installation and maintainer documentation.

The README accurately describes the intent: force an LLM to orient itself before judging a codebase, cite every finding, and produce a persistent `TECH_DEBT_AUDIT.md`. The actual risk is not implementation rot, but prompt/protocol drift: duplicated docs, Claude-specific assumptions, and lack of example outputs make the skill harder to port, test, and maintain.

## Findings

| ID | Category | File:Line | Severity | Effort | Description | Recommendation |
|----|----------|-----------|----------|--------|-------------|----------------|
| F001 | Documentation drift | `SKILL.md:30` | RESOLVED | S | The executable protocol required `TodoWrite`, a Claude-specific tool. In non-Claude runtimes, the instruction was not actionable. | Resolved by adding host-runtime fallback language. |
| F002 | Documentation drift | `SKILL.md:87` | RESOLVED | S | The large-repo section referenced Claude's `Task tool` without fallback. | Resolved by making subagent dispatch conditional on host-runtime support and adding serial module fallback. |
| F003 | Consistency rot | `README.md:59` / `SKILL.md:118` | RESOLVED | S | Project-only installation commands were formatted differently across README and SKILL docs. | Resolved by standardizing README project install formatting. |
| F004 | Documentation drift | `README.md:65` / `SKILL.md:124` | RESOLVED | S | Verification instructions differed between README and SKILL docs. | Resolved by standardizing README verification on `echo "/skills" | claude | grep tech-debt-audit`. |
| F005 | Test debt | `README.md:154` | RESOLVED | M | Contribution guidelines require testing against two real codebases, but the repository contained no fixture, golden output, or lightweight validation script for contributors. | Resolved by adding `examples/toy-python-service`, `TECH_DEBT_AUDIT.expected.md`, and `scripts/validate-fixture.ps1`. |
| F006 | Test debt | `SKILL.md:62` | RESOLVED | S | The deliverable guidance said to aim for 30–80 findings without repo-size qualification. | Resolved by limiting the target to substantial repos and instructing small repos to report only material findings. |
| F007 | Dependency & config debt | `README.md:44` | RESOLVED | S | The repo documents installation commands but had no machine-readable metadata for the skill package beyond frontmatter in `SKILL.md`. | Resolved by adding `skill.json` with schema version, entry point, output, source, and runtime notes. |
| F008 | Documentation drift | `README.md:39` | RESOLVED | S | README said the skill runs stack tools like `knip`, `madge`, `depcheck`, `pip-audit`, etc. without clearly saying missing tools are skipped. | Resolved by adding "when available" and explicit missing-tool behavior. |
| F009 | Architectural decay | `SKILL.md:97` | RESOLVED | M | The protocol and human documentation were separated by a divider inside one 225-line file, which invited accidental edits to executable protocol while changing docs. | Resolved by keeping `SKILL.md` focused on the executable protocol and moving maintainer notes to `docs/maintainer-notes.md`. |

## Top 5 "if you fix nothing else, fix these"

1. **No unresolved findings remain in this audit.** F001-F009 were resolved in the current working tree.
2. **Future maintenance:** keep the fixture validation passing and avoid reintroducing runtime-specific assumptions without fallbacks.

## Quick wins

- [x] F001: Add a non-Claude fallback for `TodoWrite`.
- [x] F002: Add a non-Claude fallback for `Task tool` / subagent dispatch.
- [x] F006: Clarify that 30–80 findings is for substantial repos, not tiny repos.
- [x] F003: Standardize project-only install instructions.
- [x] F004: Standardize verification instructions.
- [x] F008: Add "when available" to the stack-tooling claim.
- [x] F005: Add fixture/golden-output examples.
- [x] F007: Consider machine-readable skill metadata for broader ecosystems.
- [x] F009: Split protocol and maintainer docs.

## Things that look bad but are actually fine

- `SKILL.md` is 225 lines, but this is not a "god file" in the usual code sense. The single-file shape is acceptable for a skill while the protocol remains this small.
- The lack of language manifests (`package.json`, `pyproject.toml`, etc.) is fine because this repo is not an executable package.
- The blunt tone in `SKILL.md:17` looks severe, but it is intentional protocol design for reducing generic, padded LLM audit output.
- The absence of automated dependency audits is fine for the current repo contents because there are no runtime dependencies.

## Open questions for the maintainer

None for this pass. The audit's original open questions were resolved by adding portable-runtime fallbacks, a fixture/golden-output example, a validation script, machine-readable metadata, and separated maintainer notes.
