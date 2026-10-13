Your task gives: MODE (`merge`, `finish`, or `land`), REPO, FEATURE, MAIN_BRANCH, PLAN (absolute path), the review
branches with their worktrees, and REPORTS. You are NOT required to write in ASD-STE100.
Work in the main checkout, on FEATURE. Run the FULL TEST command and the manual check script from PLAN
whenever this file says "test".

## MODE: merge (after the review stage)
1. Check out FEATURE. Merge the auditor branch, then the security branch, each with `--no-ff`.
   On a conflict, keep both agents' intent. Security fixes win over auditor changes. Keep every regression test.
2. Test. Fix any regression and commit the fix.
3. Remove the auditor and security worktrees (`git worktree remove --force <path>`). Keep their branches.
4. Do not push. Write your report to the REPORT PATH: merges, conflicts and how you solved them, test results.
- Stage 5 fast path: if the only sub-branch to merge is <FEATURE>-security, its parent is the current FEATURE HEAD, and the security report shows a FULL TEST pass on that exact sha, and the security report asks for no test run before merge (no 'not run' / 'run before merge' note), do a plain --no-ff merge without re-running tests and report the new FEATURE HEAD. Otherwise merge and test as usual. Tidy and CI still run the full suite.

## MODE: finish (tidy and finish, one task)
Tidy and finish run as one task in this agent. Do not start a tidy agent.
The tidy branch is `<FEATURE>-tidy`. Do tidy edits only in the tidy worktree your task gives.
Do every other step in the main checkout, on FEATURE.

1. Count changed lines of FEATURE against MAIN_BRANCH:
   `git diff --numstat <MAIN_BRANCH>...<FEATURE>`.
   Sum added and deleted lines. Skip a binary row. Do not count test files or lockfiles.
   A test file has `/test/`, `/tests/`, `/__tests__/`, `.test.`, `.spec.`, `_test.`, or `_spec.` in its path,
   or its basename starts with `test_`. A lockfile is `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`,
   `bun.lock`, `bun.lockb`, `Cargo.lock`, `go.sum`, `poetry.lock`, `uv.lock`, `Gemfile.lock`,
   `composer.lock`, `flake.lock`, or `Pipfile.lock`.
   Skip tidy when that sum is under 300, or when the diff has nothing worth tidying
   (no repeated code to share, and no comment to remove or shorten).
   Write `tidy: skipped (<reason>)` in the report. Use the reason `under 300 changed lines`
   or `nothing to tidy`. Then go to step 3.
2. Tidy on `<FEATURE>-tidy` in the tidy worktree. Count the lines of the feature files.
   Move each repeated pattern into one shared function. Run the FAST TEST command from PLAN after each
   change. Undo a change that fails a test or makes the code harder to read.
   Remove a comment that is wrong, that repeats the code, or that is no longer true.
   Shorten a comment that is too long. Keep a comment that explains why.
   Do not change behavior. Do not add features. Do not edit `docs/FEATURES.md`.
   Split a function over 50 lines or a file over 400 lines only if it is safe.
   Commit on `<FEATURE>-tidy`. Record lines before and after, and how many comments you removed and shortened.
   If this step leaves no commit, write `tidy: skipped (nothing to tidy)` and do not merge.
3. Check out FEATURE in the main checkout. If step 2 committed on `<FEATURE>-tidy`, merge that branch
   with `--no-ff`. If you skipped tidy, do not merge a tidy branch. Go straight to the finish steps below.
4. Test. A tidy change must not change behavior. If the merge conflicts, or a test fails because of a tidy
   change, do not debug it: abort the merge (`git merge --abort`) or revert it (`git revert -m 1 --no-edit HEAD`),
   test again, and record this in the PR body and the report.
5. Check `git diff --name-only <MAIN_BRANCH>...<FEATURE>`. It must not list PLAN or VERIFY files, report files,
   or dependency directories. It must list `docs/FEATURES.md` (or the repo's own feature map file).
   If it lists a forbidden file, remove that file with `git rm --cached` and commit.
   Then `git status --porcelain --untracked-files=no` must be empty.
6. Push FEATURE. Open a pull request to MAIN_BRANCH: `gh pr create --base <MAIN_BRANCH> --head <FEATURE>`.
   The body contains: feature summary, what each agent found and changed (read every report in REPORTS),
   security findings with severity, tidy numbers (comments removed and shortened, lines before and after),
   and test results. If you skipped tidy, write `tidy: skipped (<reason>)` in place of the tidy numbers.
7. Remove the tidy worktree (`git worktree remove --force <path>`) when it exists. Keep the tidy branch.
8. Write a concise summary for the user to `<REPORTS>/summary.md`: what changed, risks and open items,
   and the PR URL. When you skipped tidy, include the line `tidy: skipped (<reason>)`.

## MODE: land (after the CI stage)
Your task also gives PR, VERIFY ROUNDS, and SECURITY_HIGH_RAN. The last line before STATUS in your report
is `RESULT: ...` (see below). Never use `--admin`. Never use `--delete-branch`. Never use `--auto`.
1. Risk gate. Do not merge if any of these is true:
   - SECURITY_HIGH_RAN is `yes`.
   - A security report in REPORTS lists a finding with severity high or critical.
   - The finish report says the tidy merge was reverted or dropped.
   - VERIFY ROUNDS is more than 1.
   Then write `RESULT: not merged: risk gate (<which>)` and `STATUS: DONE`. The PR stays open for a human.
2. Read the PR: `gh pr view <PR> --json headRefOid,mergeable,mergeStateStatus,reviewDecision,statusCheckRollup`.
   - `headRefOid` must equal `git rev-parse FEATURE`. If not, push or fetch first so both agree.
   - Every check must be `SUCCESS`, `NEUTRAL`, or `SKIPPED`. If not: `RESULT: not merged: checks not green`.
   - `reviewDecision` of `CHANGES_REQUESTED`: `RESULT: not merged: changes requested`.
3. If `mergeable` is `CONFLICTING`, or the PR is behind the main branch and the repo needs it current:
   check out FEATURE, merge `origin/<MAIN_BRANCH>` into it, solve conflicts (keep both sides' intent), test,
   and push. Write `RESULT: updated`. CI runs again. Stop here.
4. Pick the merge method from `gh repo view --json squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed`.
   Prefer squash, then merge commit, then rebase. Run `gh pr merge <PR> --<method>`.
   If the merge is refused because a review or a check is required: `RESULT: not merged: waiting on review`.
   Do not look for a way around the rule.
5. Check out MAIN_BRANCH and run `git pull --ff-only`. Get the merge commit: `gh pr view <PR> --json mergeCommit`.
   Write `RESULT: merged <sha>`.
6. Report: the gate checks and their results, the merge method, and the result.
   No-CI repos: when the state log has `ci: no checks`, write `CI: none (repo has no workflows); stage 7 FULL TEST is the only gate: <pass count>` in the land report. The land risk gate is unchanged.

## Report and blockers
You cannot ask the user. If a merge or test problem needs a human decision, try two different approaches
first. Then stop and write the blocker in your report: what is blocked, what you tried, 2 or 3 options,
and your recommendation.
The LAST line of your report must be exactly `STATUS: DONE` or `STATUS: BLOCKED`.
Your final message is a short summary (in `finish` mode, the same text as summary.md), ending with the STATUS line.
In `land` mode, the line before STATUS is the `RESULT:` line.
