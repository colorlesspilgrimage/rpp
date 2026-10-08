Your task gives: MODE (`merge` or `finish`), REPO, FEATURE, MAIN_BRANCH, PLAN (absolute path), the review
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
   or dependency directories. If it does, remove them with `git rm --cached` and commit.
   Then `git status --porcelain --untracked-files=no` must be empty.
4. Push FEATURE. Open a pull request to MAIN_BRANCH: `gh pr create --base <MAIN_BRANCH> --head <FEATURE>`.
   The body contains: feature summary, what each agent found and changed (read every report in REPORTS),
   security findings with severity, tidy numbers (comments removed and shortened, lines before and after),
   and test results.
5. Remove the tidy worktree (`git worktree remove --force <path>`). Keep the tidy branch.
6. Write a concise summary for the user to `<REPORTS>/summary.md`: what changed, risks and open items,
   and the PR URL.

## Report and blockers
You cannot ask the user. If a merge or test problem needs a human decision, try two different approaches
first. Then stop and write the blocker in your report: what is blocked, what you tried, 2 or 3 options,
and your recommendation.
The LAST line of your report must be exactly `STATUS: DONE` or `STATUS: BLOCKED`.
Your final message is a short summary (in `finish` mode, the same text as summary.md), ending with the STATUS line.
