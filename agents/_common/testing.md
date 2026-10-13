## Testing protocol
- Trace: every acceptance criterion in PLAN has at least one named test. PLAN has a matrix: criterion, then test.
- Layers: unit tests for pure logic. Integration tests at I/O boundaries. The manual check script is the
  end-to-end test.
- Determinism: no test uses the network, the wall clock, random values without a seed, or test order.
- Coverage: if PLAN has a `COVERAGE:` command, at least 85% of the changed lines are covered.
  Do not gate the coverage of the whole repo.
  Include only new or changed production files, so unchanged files cannot raise the total. The list is the production files changed in `git diff <MAIN_BRANCH>...HEAD`; if the work must change another file, change it and add it. Never shape the code to keep a file out of the list. (Fern slice-4, 2026-10-13)
- Edge cases: use boundary-value analysis and equivalence partitions. Use property-based tests where the
  ecosystem has them (Hypothesis, fast-check, proptest).
- Security checklist: OWASP ASVS Level 1 for apps and APIs. OWASP Top 10 for web features.
  CWE Top 25 for code-level flaws. OWASP Top 10 for LLM applications if the feature calls an LLM.
  Give each security finding a CWE or ASVS id.
- Dependencies and secrets: if the tool exists, run the dependency audit (`npm audit`, `pip-audit`,
  `cargo audit`, or `govulncheck`) and `gitleaks` on the diff.
- UI: if the feature has a UI, check the WCAG 2.2 AA basics (labels, keyboard use, contrast, focus).
- Keyboard and list e2e: use data with at least 3 rows, and drive real key presses (ArrowDown, ArrowUp, Enter, Tab, Escape) with page.keyboard; do not use focus() or one-row filters as a stand-in. The plan states what every navigation key does, including keys that must NOT act. (Fern slice-4, 2026-10-13)
- Screenshot or visual baselines: generate and check them only in the image CI runs (for example mcr.microsoft.com/playwright:v<locked version>-noble), through a repo script; never --update-snapshots on the box or a cloud-agent VM. Pin the CI e2e jobs to that image or OS. The verifier checks every family in the font stack (fc-match each one), not only the fallback. (Fern slice-5, 2026-10-13)
