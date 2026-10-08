# RPP for OMP: Robust Pipeline Project

RPP turns a one-line feature request into a reviewed pull request. You give it a repo and a feature prompt.
A supervisor agent then runs a fixed pipeline of specialist agents: plan, implement, verify, four parallel
reviews, merge and PR, then a feedback stage that improves the pipeline itself. You are only asked a question when an agent is stuck.

This repo contains the pieces for OMP and an installer:

| Path | What it is |
| --- | --- |
| `skills/rpp/SKILL.md` | The `rpp` skill. It is the **supervisor**: it runs the stages, checks reports, and talks to you. It never writes feature code. |
| `agents/rpp-*.md` | Ten specialist agents, one per job (see below). |
| `install.sh` | Copies the skill and agents into `~/.omp/agent/`. |
| `sync-back.sh` | Copies installed pipeline files back into this repo, keeping the default models. Used by `rpp-feedback`. |

## Why a pipeline

One agent that plans, codes, tests, and reviews its own work tends to trust itself. RPP splits the work so that:

- Each stage starts with a **fresh context** and reads only a written artifact (`PLAN.md`, `VERIFY.md`, reports).
  The verifier does not trust the implementer's claims.
- Cheap, fast models do the bulk work. Stronger models do planning-critical and review-critical work.
- Four reviewers work **in parallel on separate git worktrees**, so they cannot step on each other.
- The supervisor keeps a small context. It reads reports, not transcripts.

## Prerequisites

**Tools**
- OMP (the `omp` CLI), with the `task` tool and subagents available.
- `git` 2.5 or newer (worktrees).
- [`gh`](https://cli.github.com/), authenticated: `gh auth status` must pass.
- `bash`, `sed`, `grep` (used by the installer).
- `tmux` (recommended, so a run survives a closed terminal).

**Model access.** The agents use these models by default. Check yours with `omp --list-models`.
- `anthropic/claude-opus-5-5`: auditor, security, security-high, integrator, feedback.
- `anthropic/claude-sonnet-5-5`: planner, verifier.
- `xai-oauth/grok-4.7`: implementer, locreducer, commentcleaner.

The installer lets you pick a model for each agent (see [Install](#install)).

**The target repo**
- A git repo with a clean working tree. The supervisor aborts preflight otherwise.
- An `origin` remote that you can push to, and a default branch (`main` unless the repo says otherwise).
- A working **test command**. Several stages run the full suite and fail without one.

**Optional: Telegram.** With the [`omp-telegram`](#telegram-optional) plugin, the supervisor asks you
questions and sends the final summary through Telegram. Without it, it uses normal terminal prompts and replies.

## Install

```sh
./install.sh
```

The installer copies the ten agents to `~/.omp/agent/agents/` and the skill to `~/.omp/agent/skills/rpp/`.
It then asks which model each agent should use. The default is shown in brackets. Press Enter to keep it:

```
rpp-implementer
  RPP stage 2. Reads PLAN.md in a fresh context, then implements the feature and its tests exactly as planned.
  model [xai-oauth/grok-4.7]:
```

Run `omp --list-models` to see valid ids. Without a terminal (piped input or CI), every agent keeps its default.
Set `PI_CODING_AGENT_DIR` to install somewhere else. The installer prints the models in use afterwards. Re-run it any time to update or change models.

Verify: start `omp`, run `/agents`, and confirm ten `rpp-*` agents are listed with the models you expect.

### OMP settings to check

Set these with `omp settings`:

- `async.enabled = true`: stage 4 agents run as background jobs.
- `task.maxConcurrency >= 4`: stage 4 runs four agents at once.
- `task.softRequestBudget`: default 200 requests per subagent. Raise it if the implementer needs more.
- `task.maxRuntimeMs`: hard wall-clock limit per subagent, for example `2700000` (45 minutes).
- **Tool approvals:** subagents run without prompts, but the supervisor session does not. Pre-approve `git`, `gh`,
  and `mkdir`. Telegram cannot approve tool prompts. Use yolo mode only inside a VM, container, or dedicated user.

### Telegram (optional)

```
omp plugin install omp-telegram
/telegram setup                    # token, pairing, diagnostics
/telegram set profile daemon       # headless host: telegram_ask and telegram_send only
/telegram doctor
```

## Run

Start the supervisor on a cheap model, ideally inside tmux. The supervisor does no heavy work.

```sh
tmux new -s rpp
omp --model anthropic/claude-sonnet-5-5:low
```

Then, in the terminal or via the Telegram bot:

```
Run the rpp skill on ~/code/myrepo: add CSV export to the report command
```

To continue after a crash, run `Run the rpp skill resume` in the same repo. The supervisor reads its state
file and continues from the recorded stage.

## How the pipeline runs

```
 preflight ─► 1 Plan ─► 2 Implement ─► 3 Verify ─┬─ PASS ─► 4 Review x4 (parallel) ─► 5 Integrate ─► PR ─► 6 Feedback
                              ▲                  │
                              └──── FAIL ◄───────┘ (one automatic retry, then ask you)
```

**Preflight.** The supervisor checks that the working tree is clean, `gh auth status` passes, and `origin`
exists. It creates the branch `feat/<slug>-<MMDD-HHMM>` and a run directory at `<repo>/.git/rpp/<run>/`.
That directory holds `state.md` and all agent reports. It lives inside `.git`, so it is never committed.

**1. Plan: `rpp-planner`** (Sonnet). Explores the repo and writes `PLAN.md`: goal, repo context, ordered
implementation steps, tests, acceptance criteria, a manual check script, and risks. It writes no code. If the
prompt is too vague, it blocks with specific questions rather than guessing.

**2. Implement: `rpp-implementer`** (Grok). Starts with no context except `PLAN.md`. Implements the feature and
its tests, runs the suite, and commits.

**3. Verify: `rpp-verifier`** (Sonnet). Works in a fresh context and fixes nothing. It diffs against the main
branch, checks every plan step and acceptance criterion, runs the full suite, and drives the real program using
the plan's manual check script. It writes `VERIFY.md`, which ends with `VERDICT: PASS` or `VERDICT: FAIL`.
On FAIL the implementer gets the defect list and tries again. If the second round also fails, the supervisor
asks you.

**4. Review: four agents in parallel.** Each gets its own branch (`<feature>-<name>`) and git worktree
(`../.rpp-wt-<slug>/<name>`), and only touches files the feature changed.

| Agent | Model | Job |
| --- | --- | --- |
| `rpp-auditor` | Opus | Tries to break the program: invalid input, empty, huge, malformed, unicode, boundary values, wrong order of operations. Fixes defects and adds regression tests. |
| `rpp-security` | Opus | Looks for flaws that can harm an end user's machine (injection, path traversal, unsafe deserialization, unsafe temp files, leaked secrets, unsafe defaults). For each: failing test, patch, passing test, severity. |
| `rpp-locreducer` | Grok | Moves repeated code patterns into shared functions. No behavior change. Undoes any change that breaks a test or hurts readability. Reports line counts before and after. |
| `rpp-commentcleaner` | Grok | Removes wrong or redundant comments, shortens verbose ones, keeps the ones that explain *why*. No logic changes. |

If `rpp-security` cannot patch a flaw, the supervisor asks you before running `rpp-security-high`
(Opus at High effort). See [High-effort gate](#high-effort-gate).

**5. Integrate: `rpp-integrator`** (Opus). Merges the four branches into the feature branch with `--no-ff`
(auditor, security, commentcleaner, locreducer; security fixes and regression tests win conflicts), re-runs the
suite and the manual check, and deletes the pipeline files from the repo (`PLAN*.md`, `VERIFY*.md`,
`*-report.md`, `*-rereview.md`). It then pushes, opens the PR with `gh pr create`, removes the review
worktrees (the review branches are kept), and writes `summary.md`. The supervisor sends you that summary
and the PR link.

**6. Feedback: `rpp-feedback`** (Opus, High effort). Runs after the PR is open, and after an aborted run that
got past planning. It reads `state.md` (the supervisor logs stage times, verify rounds, blockers, and your
answers there) and every report, and looks for waste, escaped defects, and avoidable questions. It then:

- Makes at most three small, evidence-backed edits to the installed pipeline (`~/.omp/agent/`). It cannot
  change models or effort levels, add or remove stages, weaken the safety rules, or edit itself.
- If it changed anything, runs `sync-back.sh` to copy the changes into this repo, commits them as
  `feedback: ...`, and pushes to `origin main`. It does nothing if this checkout is dirty or not on `main`.
- Keeps cross-repo lessons in a marked block of global memory, `~/.omp/agent/AGENTS.md`, which every OMP
  session loads. Lessons about one repo go in `<repo>/.git/rpp/lessons.md`, which later runs on that repo read.

It writes `feedback.md` and you get one short message about what changed. It never blocks or asks you
anything. The installer writes this repo's path into the agent, so re-run `install.sh` if you move the repo.

### Blockers

Agents cannot ask you anything. Each agent gets two attempts at a problem: if the first approach fails it
tries a clearly different one. If that fails too, it writes `STATUS: BLOCKED` with the options and a
recommendation. Only then does the supervisor ask you, with 2 to 4 options and a free-text answer.
The agent restarts with `USER DIRECTION: <your answer>`. You can answer `abort` to stop the run.
You get no progress messages.

### High-effort gate

The supervisor never starts a High-effort agent without a clear yes from you. It tells you the agent,
the model, why it is needed, and that it costs more. Your yes covers exactly one run. Today only
`rpp-security-high` needs it. `rpp-feedback` also runs at High, but you approve it once for all runs by
installing it. Planner and integrator run at medium.

### Report convention

Every agent writes a report to the path it is given. The last line is exactly `STATUS: DONE` or
`STATUS: BLOCKED`. The verifier also ends `VERIFY.md` with `VERDICT: PASS` or `VERDICT: FAIL`.
The supervisor reads only those last lines and the reports, which keeps its context small.

## Notes and guarantees

- The supervisor never edits feature code, never merges or pushes itself, never deletes branches, and never
  force-pushes. Only the integrator pushes to the target repo. Only `rpp-feedback` pushes to this repo.
- Agents write documents, reports, comments, and commit messages in
  [ASD-STE100](https://www.asd-ste100.org/) (Simplified Technical English). The integrator's summary is exempt.
- State and reports are in `<repo>/.git/rpp/<run>/`. Worktrees are in `../.rpp-wt-<slug>/` and the integrator
  removes them. The four review branches are kept.
- Agents may not change the model they run on, and the supervisor may not override an agent's model.
  Each step uses the model you chose at install time. To change a model, re-run `install.sh`.

## License

MIT. See [LICENSE](LICENSE).
