# rpp: Robust Pipeline Project for Grok Bot

rpp turns a feature prompt into a reviewed, tested, merged pull request. A team of Grok Bot bots runs it.
One supervisor bot talks to the owner. Seven stage bots each do one job, each through one cloud coding agent per task.
The owner is asked only when a bot is stuck, a gate needs a decision, or a budget runs out.

This repo is a guide to recreate that setup in your own Grok Bot. It replaces the earlier CLI skill, agents, and installer.

## The 10 stages

```
1 Plan ─► 2 Implement ─► 3 Verify ─┬ PASS ─► 4 Security+Audit ─► 5 Merge ─► 6-7 Tidy+Finish (PR) ─► 8 CI loop ─► 9 Land ─► 10 Feedback
              ▲                    │
              └──── FAIL ◄─────────┘ (1 automatic retry; a 2nd FAIL goes to the owner)
```

| Stage | Bot | What happens |
|---|---|---|
| 1 Plan | planner | Explores the repo and writes a self-contained `PLAN.md` (or one plan per slice for a queue). No code. |
| 2 Implement | implementer | Implements the feature and tests exactly as PLAN says, on the run branch. |
| 3 Verify | verifier | Checks the work against PLAN, runs every test, drives the program. Fixes nothing. Writes `VERIFY-<n>.md`. |
| 4 Security+Audit | security | Tries to break the feature and patches security flaws on `<FEATURE>-security`. |
| 5 Merge | integrator | Merges `<FEATURE>-security` into FEATURE (fast path when nothing needs re-testing). |
| 6-7 Tidy+Finish | integrator | One task: optional tidy on `<FEATURE>-tidy`, full suite, open the PR, write `summary.md`. |
| 8 CI | supervisor + ci-fixer | The supervisor watches PR checks every 10 minutes; the CI fixer fixes red runs (max 5 attempts). |
| 9 Land | integrator | Merges the PR only past the land risk gate. |
| 10 Feedback | feedback | Learns from the run: updates repo lessons, proposes up to 3 pipeline edits. |

## Bot lineup

| File | Bot | Stages | Default cloud-agent effort |
|---|---|---|---|
| [bots/supervisor.md](bots/supervisor.md) | rpp Supervisor | all (orchestration) | none for stage work |
| [bots/planner.md](bots/planner.md) | rpp Planner | 1 | medium |
| [bots/implementer.md](bots/implementer.md) | rpp Implementer | 2 | high |
| [bots/verifier.md](bots/verifier.md) | rpp Verifier | 3 | medium |
| [bots/security.md](bots/security.md) | rpp Security | 4 | high (xhigh once per owner yes) |
| [bots/integrator.md](bots/integrator.md) | rpp Integrator | 5, 6-7, 9 | medium (retry high) |
| [bots/ci-fixer.md](bots/ci-fixer.md) | rpp CI Fixer | 8 | medium |
| [bots/feedback.md](bots/feedback.md) | rpp Feedback | 10 | high |

The original lineup used first names: Rosa (supervisor), Paul (planner), Ivan (implementer), Vera (verifier),
Sid (security), Gus (integrator), Cy (CI fixer), and Fern (feedback). The guide refers to roles only.

Earlier versions had 13 bots. The auditor merged into security, tidy and integrator escalation merged into the
integrator, and the high-effort security and alternate implementer bots were retired. Their jobs are now
sections of `bots/security.md` and `bots/integrator.md`.

## Quick start

1. Read [SETUP.md](SETUP.md) and create the 8 bots from `bots/`.
2. Connect GitHub for every bot. Copy the rule files to the box and set up the toolchain (SETUP steps 2-5).
3. Read [RULES.md](RULES.md). Adjust budgets and models to your account, in RULES.md and the bot files together.
4. In the supervisor's chat, give it a repo and a feature prompt, for example:
   `Run rpp on <OWNER>/<REPO>: add CSV export to the report command`.
   For a queue: `Run rpp on <OWNER>/<REPO> for these slices, in order: 1. ... 2. ...`.
   Add `no-merge` to leave the PR open for you.
5. The supervisor reports one line per stage result and asks you only when a decision is needed.

## Repo layout

| Path | What it is |
|---|---|
| `README.md` | This file. |
| `SETUP.md` | Step-by-step recreation in Grok Bot. |
| `RULES.md` | The full cross-bot rules: chain of command, handoff format, limits, safety, models, gates, FEEDBACK APPLY, lessons. |
| `STANDARDS.md` | Code and test rules that bots paste into every cloud-agent prompt. |
| `bots/<role>.md` | One file per bot: profile fields and its instructions. |
| `templates/` | Blank `state.md`, `PLAN.md`, report skeletons, and an empty `GLOBAL-LESSONS.md`. |
| `LICENSE` | License. |
