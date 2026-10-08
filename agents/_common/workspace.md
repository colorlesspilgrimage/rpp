## Workspace (worktree agents only)
Your task gives FEATURE_BRANCH, BRANCH, and WORKTREE. The supervisor creates WORKTREE on BRANCH.
1. If WORKTREE does not exist, run: `git -C <REPO> worktree add -b <BRANCH> <WORKTREE> <FEATURE_BRANCH>`
   (without `-b` if BRANCH exists).
2. Do ALL reading, editing, and test runs inside WORKTREE. Use absolute paths. Set the working
   directory of every command to WORKTREE. The read, edit, and write tools do not use that working
   directory. They resolve a relative path against the main checkout. Give them WORKTREE paths only.
3. Never change files in the main checkout. Never change other agents' worktrees.
4. The supervisor links the dependency directories that PLAN lists. If the tests cannot find dependencies,
   run the PLAN SETUP command once in WORKTREE. Never commit dependency directories or links to them.
5. Scope: only files this feature changed. Find them with `git diff --name-only <MAIN_BRANCH>...<FEATURE_BRANCH>`.
6. Commit your work on BRANCH when you finish.
