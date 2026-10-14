---
name: comslop
description: >-
  When the user asks to run comslop or to strip explanatory comment noise from a
  repo: launch a Grok 4.7 high-effort cloud agent that removes every comment
  except ones explaining implementation quirks.
---
# comslop

Remove comment noise from a repository. A comment stays only when it explains a **quirk of the implementation**: the non-obvious reason something is done a certain way. Examples are a workaround for a library or platform bug, odd bit math for an edge case, an ordering dependency, a performance trick, or a constraint that comes from outside the code. Everything else goes, including comments that explain how the code works, restate what it does, describe parameters or returns the names already make clear, section banners, stale TODOs with no context, and commented-out code.

## 1. Work out the scope
Get these from the user's prompt and the conversation:
- **Repo**: the GitHub URL.
- **Paths**: the whole repo by default, or only the directories, files, or languages they named.
- **Branch**: the default branch unless they named another.
- **Landing**: open a PR and merge it with a normal merge once CI and all checks pass. If any check fails, leave the PR open and don't merge. Never use --admin, --delete-branch, or force-push.

If the repo is unclear, or the paths are ambiguous enough to change the result, ask the user with one widget before launching. Don't guess the repo.

## 2. Launch the cloud agent
Use CloudAgent with action "launch", model `grok-4.7`, and model_params `{"reasoning_effort": "high"}`. Brief it like this, filling in the scope:

> In <repo> on <branch>, limited to <paths>, remove every code comment except ones that explain a quirk of the implementation: a non-obvious *why*, such as a workaround, odd math for an edge case, an ordering or timing dependency, a performance trick, or an outside constraint. Delete comments that explain *how* or *what* the code does, restate the code, give obvious docs for params or returns, are banners or dividers, are TODOs with no context, or are commented-out code. When a comment mixes the two, cut it down to just the quirk.
> Keep these no matter what: license and copyright headers, shebangs, tool directives (eslint-disable, @ts-expect-error, # type: ignore, noqa, pragma, //go:, build tags), JSDoc or docstrings on a public or exported API that generate published docs, and anything inside string literals.
> Change comments only. Don't touch any code, formatting, or whitespace except blank lines a removed comment leaves behind. Skip vendored, generated, lockfile, and node_modules content.
> Run the project's lint, typecheck, build, and tests. They must pass exactly as they did before you started.
> Commit on a branch named `chore/comslop-<date>` and open a PR. Wait for CI and all checks on the PR. If every one passes, merge it with a normal merge. If any fails, leave it open and say why. Never use --admin, --delete-branch, or force-push. In the PR body, give the number of comments removed per file and list every comment you kept with a one-line reason why.
> Report back with the PR URL, the merge SHA if it merged, the counts of comments removed and kept, the check results, and any comment you weren't sure about.

## 3. Report to the user
Once it finishes, send the PR link, the removed and kept counts, and any borderline comments the user should look at. If the checks didn't pass, say which ones failed and that the PR is still open.
