## Testing protocol
- Trace: every acceptance criterion in PLAN has at least one named test. PLAN has a matrix: criterion, then test.
- Layers: unit tests for pure logic. Integration tests at I/O boundaries. The manual check script is the
  end-to-end test.
- Determinism: no test uses the network, the wall clock, random values without a seed, or test order.
- Coverage: if PLAN has a `COVERAGE:` command, at least 85% of the changed lines are covered.
  Do not gate the coverage of the whole repo.
- Edge cases: use boundary-value analysis and equivalence partitions. Use property-based tests where the
  ecosystem has them (Hypothesis, fast-check, proptest).
- Security checklist: OWASP ASVS Level 1 for apps and APIs. OWASP Top 10 for web features.
  CWE Top 25 for code-level flaws. OWASP Top 10 for LLM applications if the feature calls an LLM.
  Give each security finding a CWE or ASVS id.
- Dependencies and secrets: if the tool exists, run the dependency audit (`npm audit`, `pip-audit`,
  `cargo audit`, or `govulncheck`) and `gitleaks` on the diff.
- UI: if the feature has a UI, check the WCAG 2.2 AA basics (labels, keyboard use, contrast, focus).
