# PLAN: <slug>

## 1. Goal and non-goals
Feature prompt (exact): <prompt>
Non-goals:

## 2. Repo context
Stack, entry points, run command, conventions:
SETUP: <install command for a fresh checkout>
FAST TEST: <tests for the changed files only>
FULL TEST: <every suite CI runs that the box can run>
LINT: <formatter, linter, type checker | none>
COVERAGE: <per-file coverage of new or changed production files, 85% | none>
SHARED DEPENDENCY DIRECTORIES: <dirs | none>
Environment facts (label each one): `box: ...`, `cloud-agent VM: ...`

## 3. Implementation steps
1. <file path, function or module>

## 4. Structure
<where each new file goes, and why>

## 5. Tests to write
<file paths, cases, edge cases, expected results>

## 6. Acceptance criteria
- [ ] <user-visible behavior>

| Criterion | Test |
|---|---|

## 7. Feature map entry
<exact text for docs/FEATURES.md>

## 8. Manual check script
<exact commands, inputs, expected outputs>

## 9. Risks and open assumptions
- <checked fact, with source> / UNCHECKED: <fact>
- ASSUMPTION (unmerged <slice>): <what this plan assumes>
