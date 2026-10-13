# Recreate rpp in Grok Bot

This guide describes what the original setup used. Placeholders: `<REPO>` is the target repo, `<OWNER>` its
GitHub owner, `<RPP_REPO>` your copy of this guide repo. Box paths are the suggested defaults; if you change
one, change it in every file.

## 1. Choose how bots get their rules

**Recommended: rules in box files.** Each bot's instructions live in a box file that the bot reads at the
start of every task. The supervisor's FEEDBACK APPLY edits those files, so improvements reach the bots without
re-pasting. This is how the original setup worked.

**Alternative: pasted rules.** Paste each bot file's "Instructions" section into the bot. FEEDBACK APPLY then
needs you to re-paste edited sections by hand.

## 2. Put the rule files on the box

The box is one machine shared by all your bots, so every bot sees the same files.

```sh
mkdir -p /workspace/rpp-bots /workspace/rpp-runs/lessons
cp RULES.md STANDARDS.md /workspace/rpp-bots/
cp templates/GLOBAL-LESSONS.md /workspace/rpp-bots/GLOBAL-LESSONS.md
for r in supervisor planner implementer verifier security integrator ci-fixer feedback; do
  mkdir -p /workspace/rpp-bots/$r && cp bots/$r.md /workspace/rpp-bots/$r/REFERENCE.md
done
```

## 3. Create the bots

Create one Grok Bot bot per file in `bots/`, stage bots first:

1. Set the name, title, and description from the file's "Grok Bot profile".
2. Instructions: with box files, paste the one line the profile gives. Otherwise paste the "Instructions" section.
3. Connect GitHub.
4. Write down the bot's agent id.

Then wire the ids, in the box copies (and the pasted text, if you pasted):
- In `supervisor/REFERENCE.md`, replace each `<..._ID>` with the stage bot's id, and set the owner options
  (`FEEDBACK MERGE`, `RPP_REPO`).
- In each stage bot's file, add one line: `Supervisor id: <SUPERVISOR_ID>`.
- Never publish ids in a shared repo.

## 4. Tools each bot uses

- GitHub connector (all bots): repos, branches, PRs, check runs. The supervisor creates FEATURE with
  `create_branch` and reads CI with `list_check_runs_for_ref` and `get_commit_combined_status`. The integrator
  merges PRs with it.
- CloudAgent (stage bots): every repo change goes through a cloud agent. The supervisor uses one only for the
  FEEDBACK APPLY PR.
- SendToAgent (all bots): every handoff. Format: RULES.md section 2.
- Routines (supervisor): the CI watch.
- The box (Read, Shell): run folders, lessons, rule files.

## 5. Toolchain on the box

Bots never install anything on the box during a stage (RULES.md section 3), so set it up yourself before runs.
Match the target repo's `engines` range. The original box was Debian 13 with system Node 20, while the repo
needed Node >= 22.17:

- A Node version inside the repo's `engines` range. The original unpacked Node 22.23.3 under
  `~/.nvm/versions/node/v22.23.3`, and PLAN's SETUP line put it first:
  `export PATH=$HOME/.nvm/versions/node/v22.23.3/bin:$PATH`.
- `make` and a compiler (`build-essential`) for native modules such as better-sqlite3.
- Playwright browsers: `npx playwright install chromium`.
- `gitleaks`, if you can. Without it, bots review diffs by hand and say so.
- Never generate visual baselines on the box (STANDARDS.md).

## 6. Run folders and lessons

- Each run: `/workspace/rpp-runs/<slug>-<MMDD-HHMM>/` with `state.md` (from `templates/state.md`), `PLAN.md`,
  `VERIFY-<n>.md`, and `reports/`. The supervisor creates it.
- Slice queue plans: a folder such as `/workspace/rpp-runs/<queue>-plans/` with one `PLAN-<slice>.md` each.
- Repo lessons: `/workspace/rpp-runs/lessons/<owner>-<repo>.md`, kept by the feedback bot.
- Global lessons: `/workspace/rpp-bots/GLOBAL-LESSONS.md`, kept by the supervisor.

## 7. The CI watch routine

The supervisor owns Stage 8 (full steps in `bots/supervisor.md`):
1. When the PR opens, it checks the checks once at once and logs the result.
2. No checks at all: it treats the repo as having no CI, tells you, and goes to land.
3. Pending: a routine checks the PR every 10 minutes. A run more than 5 minutes late is checked by hand and
   reported to you.
4. Red: the CI fixer gets a task (at most 5 per CI loop). Green: the routine is deleted and land starts.

## 8. First-run checklist

- [ ] 8 bots created, each with GitHub connected.
- [ ] Rule files on the box; the supervisor has every stage-bot id; each stage bot has the supervisor id.
- [ ] Owner options set in the supervisor file.
- [ ] Box toolchain meets the target repo's `engines`.
- [ ] RULES.md models match what your CloudAgent tool lists.
- [ ] First run on a small feature with `no-merge`.
