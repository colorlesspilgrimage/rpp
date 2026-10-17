# rpp engineering standards

These are the code and test rules for every cloud agent that reads or writes code (planner, implementer,
verifier, security, integrator, CI fixer). The bot pastes this whole file into each cloud-agent prompt or attaches it as a file.
Recommended box copy: `/workspace/rpp-bots/STANDARDS.md`.

## Code structure
Follow this order. The first source that speaks wins:
1. The repo's own rules: `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING`, and the lint and format config.
2. The patterns that the repo already uses.
3. The rpp default below.

rpp default:
- Layout: the standard layout of the ecosystem (Python: `src/` and `pyproject.toml`; Node and TypeScript: `src/`
  and `tsconfig`; Go: `cmd/` and `internal/`; Rust: the cargo layout). Do not invent a layout.
- Shape: "functional core, imperative shell". Pure logic in its own modules. I/O at the edges, passed in as
  arguments. One module per feature.
- Tests: the test tree mirrors the source tree.
- Size: a function has 50 lines or fewer. A file has 400 lines or fewer. Split a unit that grows past this.
  Never put new code or tests in a file that is already at or over 400 lines; use a new file.
- Toolchain: the repo's formatter, linter, and type checker pass on the files you change.

## Tests
- PLAN gives FAST TEST (only the tests for this feature) and FULL TEST. Use FAST TEST while you work. Run
  FULL TEST once before you write your report. With no FAST TEST, use FULL TEST.
- FULL TEST includes every suite CI runs that the box can run (for example the whole Playwright suite).
  Suites only CI can run are listed as CI-only in PLAN.

## Testing protocol
- Trace: every acceptance criterion has at least one named test. PLAN has a criterion-to-test matrix.
- Layers: unit tests for pure logic, integration tests at I/O boundaries, the manual check script as end-to-end.
- Determinism: no test uses the network, the wall clock, unseeded random values, or test order.
  A rule tied to a time boundary (day end, rollover) pins the clock in its tests and covers both sides of the boundary.
- Coverage: at least 85% per new or changed production file. The file list comes from
  `git diff <MAIN_BRANCH>...HEAD`, never a frozen list. Never shape code to keep a file out of the list.
  Do not gate whole-repo coverage. Give every new production file a unit test, including code the box cannot
  run for real (for example a Postgres store tested with a stub db). A note that "CI will cover it" is not enough.
- Edge cases: boundary values and equivalence partitions. Property-based tests where the ecosystem has them.
- Security checklist: OWASP ASVS Level 1 for apps and APIs, OWASP Top 10 for web features, CWE Top 25 for
  code-level flaws, OWASP Top 10 for LLM applications when the feature calls an LLM. Every security finding
  gets a severity and a CWE or ASVS id.
- Destructive file operations: a script deletes or overwrites only files that it created in a temp directory.
  PLAN names each file a script may delete. The verifier runs each such script once with every path input
  (environment variable or argument) set to a canary file, and checks that the canary file still exists.
- Dependencies and secrets: run the dependency audit (`npm audit`, `pip-audit`, `cargo audit`, `govulncheck`)
  and `gitleaks` on the diff when the tool exists. Without gitleaks, review the diff by hand and say so.
- UI: check the WCAG 2.2 AA basics (labels, keyboard use, contrast, focus). A modal dialog keeps Tab and
  Shift+Tab inside, Escape closes it, and focus returns to the opener. PLAN names a test for each of these.
- Keyboard and list e2e: data with at least 3 rows, real key presses (ArrowDown, ArrowUp, Enter, Tab, Escape)
  through `page.keyboard`. No `focus()` or one-row filters as a stand-in. PLAN states what every navigation key
  does, including keys that must not act.
- Async UI races: tests cover a second action while one is in flight, a stale response, and a failed request.
  A screen reused for another record also tests moving from record A to record B: no field of A is saved onto B.
- Visual baselines: generate and check them only in the exact image CI runs (for example
  `mcr.microsoft.com/playwright:v<locked version>-noble`) through a repo script. Never `--update-snapshots` on
  the box or a cloud-agent VM. Pin CI e2e jobs to that image or OS. Check every family in the font stack
  (`fc-match` each one). Box e2e runs exclude visual tests. When a cloud agent cannot run that image, skip the
  visual tests, mark them not run, and treat PR CI as the authority; this is not `STATUS: BLOCKED`.

## Feature map
The repo keeps a feature map in `docs/FEATURES.md` (or the file the repo already uses). One entry per feature:
name and one-sentence purpose; entry point; numbered use steps; a check command and its expected output; code
and test paths. Keep entries short. Update an entry when its feature changes. Never remove other entries.

## Agent-readable code
Agents read this code next.
- Names say what a thing does, and a search for the name finds it. One concept, one place, one name; no aliases.
- Explicit code: flat control flow, explicit types and imports, no magic or hidden state.
- Each file reads alone. Put the contract (inputs, outputs, errors, side effects) at the top.
- Many small focused files. Related code together. No decorative formatting or abbreviations.
- A comment states a fact the code cannot show: a reason, an invariant, or a constraint.
These rules never override the repo's own rules.

## Language
Write documents, reports, code comments you add, and commit messages in ASD-STE100 (Simplified Technical
English): sentences of 20 words or fewer, one instruction per sentence, active voice, no idioms or slang.
