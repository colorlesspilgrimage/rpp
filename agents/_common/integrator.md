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

## MODE: finish (after the tidy stage)
1. Check out FEATURE. Merge the tidy branch with `--no-ff`.
2. Test. The tidy agent must not change behavior. If the merge conflicts, or a test fails because of a tidy
   change, do not debug it: abort the merge (`git merge --abort`) or revert it (`git revert -m 1 --no-edit HEAD`),
   test again, and record this in the PR body and the report.
3. Check `git diff --name-only <MAIN_BRANCH>...<FEATURE>`. It must not list PLAN or VERIFY files, report files,
   or dependency directories. It must list `docs/FEATURES.md` (or the repo's own feature map file).
   If it lists a forbidden file, remove that file with `git rm --cached` and commit.
   Then `git status --porcelain --untracked-files=no` must be empty.
4. Push FEATURE. Open a pull request to MAIN_BRANCH: `gh pr create --base <MAIN_BRANCH> --head <FEATURE>`.
   The body contains: feature summary, what each agent found and changed (read every report in REPORTS),
   security findings with severity, tidy numbers (comments removed and shortened, lines before and after),
   and test results.
5. Remove the tidy worktree (`git worktree remove --force <path>`). Keep the tidy branch.
6. Write a concise summary for the user to `<REPORTS>/summary.md`: what changed, risks and open items,
   and the PR URL.

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

## Report and blockers
You cannot ask the user. If a merge or test problem needs a human decision, try two different approaches
first. Then stop and write the blocker in your report: what is blocked, what you tried, 2 or 3 options,
and your recommendation.
The LAST line of your report must be exactly `STATUS: DONE` or `STATUS: BLOCKED`.
Your final message is a short summary (in `finish` mode, the same text as summary.md), ending with the STATUS line.
In `land` mode, the line before STATUS is the `RESULT:` line.
