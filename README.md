# RPP for OMP: Robust Pipeline Project

RPP turns a one-line feature request into a reviewed pull request. You give it a repo and a feature prompt.
A supervisor agent then runs a fixed pipeline of specialist agents: plan, implement, verify, two parallel
reviews, merge, tidy, and PR, then a CI-fix loop, an automatic merge, and a feedback stage that improves the pipeline itself. You are only asked a
question when an agent is stuck.

This repo contains the pieces for OMP and an installer:

| Path | What it is |
| --- | --- |
| `skills/rpp/SKILL.md` | The `rpp` skill. It is the **supervisor**: it runs the stages, checks reports, and talks to you. It never writes feature code. |
| `agents/rpp-*.md` | Twelve specialist agents, one per job (see below). |
| `agents/_common/*.md` | Shared sections that the installer inserts into the agents (see [Editing the agents](#editing-the-agents)). |
| `install.sh` | Builds the agents and installs them and the skill into `~/.omp/agent/`. |

## Why a pipeline

One agent that plans, codes, tests, and reviews its own work tends to trust itself. RPP splits the work so that:

- Each stage starts with a **fresh context** and reads only a written artifact (`PLAN.md`, `VERIFY-<n>.md`, reports).
  The verifier does not trust the implementer's claims.
- Cheap, fast models do the bulk work. Stronger models do planning-critical and review-critical work.
- Reviewers work **in parallel on separate git worktrees**, so they cannot step on each other. Cleanup runs
  after their fixes are merged, so it never conflicts with them.
- The supervisor keeps a small context. It reads reports, not transcripts.

## Prerequisites

**Tools**
- OMP (the `omp` CLI), with the `task` tool and subagents available.
- `git` 2.5 or newer (worktrees).
- [`gh`](https://cli.github.com/), authenticated: `gh auth status` must pass.
- `bash`, `sed`, `grep` (used by the installer).
- `tmux` (recommended, so a run survives a closed terminal).

**Model access.** The agents use these models by default. Check yours with `omp --list-models`.
- `anthropic/claude-opus-5-5`: auditor, security, security-high, integrator-escalation, feedback.
- `anthropic/claude-sonnet-5-5`: planner, implementer, verifier, integrator, ci-fixer.
- `xai-oauth/grok-4.7`: implementer-grok (the alternate implementer, picked per run).
- `anthropic/claude-haiku-5-5`: tidy.

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

The installer copies the twelve agents to `~/.omp/agent/agents/` and the skill to `~/.omp/agent/skills/rpp/`.
It then asks which model each agent should use. The default is shown in brackets. Press Enter to keep it:

```
rpp-implementer
  RPP stage 2. Reads PLAN.md in a fresh context, then implements the feature and its tests exactly as planned.
  model [anthropic/claude-sonnet-5-5]:
```

Run `omp --list-models` to see valid ids. Choices that differ from the default are saved in
`~/.omp/agent/rpp-models.conf` and offered again next time. Without a terminal (piped input, CI, or
`rpp-feedback`), saved choices are kept and the other agents get the default. Set `PI_CODING_AGENT_DIR` to
install somewhere else. The installer prints the models in use afterwards. Re-run it any time to update or
change models. It also removes agents that older versions installed (`rpp-locreducer`, `rpp-commentcleaner`).

Verify: start `omp`, run `/agents`, and confirm twelve `rpp-*` agents are listed with the models you expect.

### OMP settings to check

Set these with `omp settings`:

- `async.enabled = true`: stage 4 agents run as background jobs.
- `task.maxConcurrency >= 2`: stage 4 runs two agents at once.
- `task.softRequestBudget`: default 200 requests per subagent. Raise it if the implementer needs more.
- `task.maxRuntimeMs`: hard wall-clock limit per subagent, for example `2700000` (45 minutes).
- **Tool approvals:** subagents run without prompts, but the supervisor session does not. Pre-approve `git`, `gh`,
  `mkdir`, `mv`, and `ln`. Telegram cannot approve tool prompts. Use yolo mode only inside a VM, container, or dedicated user.

### Telegram (optional)

```
omp plugin install omp-telegram
/telegram setup                    # token, pairing, diagnostics
/telegram set profile daemon       # headless host: telegram_ask and telegram_send only
/telegram doctor
```

## Run

Start the supervisor on a cheap model, ideally inside tmux. The supervisor does no heavy work. Set the effort
level yourself: OMP defaults to high effort, which costs more than the supervisor needs. The pipeline agents
always use their own installed models and effort levels.

```sh
tmux new -s rpp
cd ~/code/myrepo
rpp-omp        # same as: omp --model anthropic/claude-sonnet-5-5:low
```

`install.sh` offers to add the `rpp-omp` alias to `~/.bashrc` or `~/.zshrc` when you run it in a terminal.
For other shells, add the equivalent of `alias rpp-omp='omp --model anthropic/claude-sonnet-5-5:low'` yourself.

Then run the skill with your feature prompt. The repo defaults to the current directory:

```
/skill:rpp add CSV export to the report command
```

Plain language also works, and is useful from the Telegram bot or to name another repo:

```
Run the rpp skill on ~/code/myrepo: add CSV export to the report command
```

To continue after a crash, run `/skill:rpp resume` in the same repo. The supervisor reads its state
file and continues from the recorded stage.

## How the pipeline runs

```
 preflight ─► 1 Plan ─► 2 Implement ─► 3 Verify ─┬─ PASS ─► 4 Review x2 (parallel) ─► 5 Merge ─► 6 Tidy ─► 7 Finish (PR) ─► 8 CI loop ─► 9 Land (merge) ─► 10 Feedback
                              ▲                  │
                              └──── FAIL ◄───────┘ (one automatic retry, then ask you)
```

**Preflight.** The supervisor checks that the working tree is clean, `gh auth status` passes, and `origin`
exists. It then asks which model does the implementation: `rpp-implementer` (default
`anthropic/claude-sonnet-5-5`) or `rpp-implementer-grok` (default `xai-oauth/grok-4.7`). The options show the model
that each installed agent uses. The answer is saved in `state.md`, so `resume` does not ask again. It creates the branch `feat/<slug>-<MMDD-HHMM>` and a run directory at `<repo>/.git/rpp/<run>/`.
That directory holds `state.md`, `PLAN.md`, the `VERIFY-<n>.md` files, and all agent reports. It lives inside
`.git`, so none of it is ever committed and the PR contains only feature changes.

`state.md` records the current stage, the status of each agent in it, and a timestamped log of stage times,
verify rounds, blockers, and your answers. `resume` uses it to skip agents that already finished, and stage 10
uses the log to find waste.

**1. Plan: `rpp-planner`** (Sonnet). Explores the repo and writes `PLAN.md`: goal, repo context, ordered
implementation steps, tests, acceptance criteria, a manual check script, and risks. It writes no code. If the
prompt is too vague, it blocks with specific questions rather than guessing. The repo context includes labeled
`SETUP`, `FAST TEST` (only the feature's tests), `FULL TEST`, and `SHARED DEPENDENCY DIRECTORIES` lines.

**2. Implement: `rpp-implementer` or `rpp-implementer-grok`** (Sonnet 5.5 or Grok 4.7, your choice at the start
of the run). Both agents share one prompt (`agents/_common/implementer.md`) and differ only in model. The agent
starts with no context except `PLAN.md`. It implements the feature and its tests, runs the tests, and commits.

**3. Verify: `rpp-verifier`** (Sonnet). Works in a fresh context and fixes nothing. It diffs against the main
branch, checks every plan step and acceptance criterion, runs the full suite, and drives the real program using
the plan's manual check script. It writes `VERIFY-<n>.md`, which records the commit it checked and ends with
`VERDICT: PASS` or `VERDICT: FAIL`. On FAIL the implementer fixes only the listed defects, and the verifier
runs in `recheck` mode: it confirms each fix, reviews only the new diff, and reruns the full suite and manual
check. If the second round also fails, the supervisor asks you.

**4. Review: two agents in parallel.** The supervisor gives each its own branch (`<feature>-<name>`) and git
worktree (`../.rpp-wt-<slug>/<name>`), and symlinks the plan's shared dependency directories into it so
dependencies are not installed again. Each agent only touches files the feature changed.

| Agent | Model | Job |
| --- | --- | --- |
| `rpp-auditor` | Opus | Tries to break the program: invalid input, empty, huge, malformed, unicode, boundary values, wrong order of operations. Fixes defects and adds regression tests. |
| `rpp-security` | Opus | Looks for flaws that can harm an end user's machine (injection, path traversal, unsafe deserialization, unsafe temp files, leaked secrets, unsafe defaults). For each: failing test, patch, passing test, severity. |

If `rpp-security` cannot patch a flaw, the supervisor asks you before running `rpp-security-high`
(Opus at High effort). See [High-effort gate](#high-effort-gate).

**5. Merge: `rpp-integrator`** (Sonnet, `merge` mode). Merges the auditor and security branches into the
feature branch with `--no-ff` (security fixes win conflicts, every regression test is kept), re-runs the full
suite and the manual check, and fixes regressions. It does not push.

**6. Tidy: `rpp-tidy`** (Haiku). Works on the merged result, so the review fixes get tidied too. It moves
repeated code into shared functions and removes or shortens wrong, redundant, or verbose comments, keeping the
ones that explain *why*. No behavior change: it undoes any change that breaks a test or hurts readability.

**7. Finish: `rpp-integrator`** (Sonnet, `finish` mode). Merges the tidy branch. If the tidy merge conflicts or
breaks a test, it drops the tidy merge instead of debugging it. It re-runs the suite and the manual check, pushes,
opens the PR with `gh pr create`, removes the worktrees (the branches are kept), and writes `summary.md`.
The supervisor sends you that summary and the PR link.

If the integrator blocks in stage 5 or 7, the supervisor runs `rpp-integrator-escalation` (Opus, medium effort)
once before it asks you.

**8. CI: `rpp-ci-fixer`** (Sonnet). The supervisor waits for the PR checks with `gh pr checks --watch`. If no
checks appear within 3 minutes, it skips this stage. If a check fails, `rpp-ci-fixer` reads the failed logs and
decides the cause: a code defect, a CI setup error, or a flaky run. It fixes the first two, reruns the third,
pushes to the feature branch, and the supervisor waits again. It never skips, disables, or weakens a check. After
10 fixer attempts, or when the fixer is blocked, the supervisor asks you.

**9. Land: `rpp-integrator`** (Sonnet, `land` mode). Merges the PR by itself, unless the prompt contains
`no-merge`. It merges only if all of these hold: CI is green on the PR's head commit, the PR has no conflicts, no
review requests changes, and the run is low-risk. A run is **not** low-risk if `rpp-security-high` ran, a security
finding was high or critical, the tidy merge was dropped, or verify needed more than one round. In those cases the
PR stays open for a human. It uses the repo's allowed merge method (squash first), and never uses `--admin`,
`--auto`, or `--delete-branch`. If the repo needs a review, it reports "waiting on review" and stops. If main moved
and the PR conflicts, it merges main into the feature branch, pushes, and the pipeline returns to stage 8
(at most 2 times, then it asks you). After a merge it fast-forwards your local main branch.

**10. Feedback: `rpp-feedback`** (Opus, High effort). Runs after the PR is open, and after an aborted run that
got past planning. It reads `state.md`, the plan, the verify files, and every report, and looks for waste,
escaped defects, and avoidable questions. It then:

- Makes at most three small, evidence-backed edits to the pipeline source in this repo. It cannot change models
  or effort levels, add or remove stages, weaken the safety rules, or edit itself or `install.sh`.
- If it changed anything, re-runs `install.sh` (your model choices are kept), commits the changes as
  `feedback: ...`, and pushes to `origin main`. It changes nothing if this checkout is dirty or not on `main`.
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
installing it. All other agents run at medium.

### Report convention

Every agent writes a report to the path it is given. The last line is exactly `STATUS: DONE` or
`STATUS: BLOCKED`. The verifier also ends each `VERIFY-<n>.md` with `VERDICT: PASS` or `VERDICT: FAIL`.
The supervisor reads only those last lines and the reports, which keeps its context small.

## Standards the agents follow

Three shared sections in `agents/_common/` set the standards. Each is included in the agents that need it.

- **Code structure** (`structure.md`). Order of precedence: the repo's own rules, then its existing patterns,
  then the RPP default. The default is the standard layout of the ecosystem, "functional core, imperative shell"
  (pure logic apart from I/O), tests that mirror the source tree, functions of 50 lines or fewer, files of
  400 lines or fewer, and the repo's formatter, linter, and type checker. The plan has `LINT:` and a Structure section.
- **Testing protocol** (`testing.md`). Every acceptance criterion maps to a named test. Tests are
  deterministic, and the verifier runs new tests 3 times. At least 85% of changed lines are covered when the repo
  has a coverage tool (`COVERAGE:` in the plan). The auditor uses boundary-value analysis and property-based tests.
  Security findings carry a CWE or OWASP ASVS id, and the checklists are ASVS Level 1, OWASP Top 10, CWE Top 25,
  and OWASP Top 10 for LLM applications. Dependency audit, `gitleaks`, and WCAG 2.2 AA basics apply when relevant.
- **Feature map** (`featuremap.md`). The target repo keeps `docs/FEATURES.md`. Each feature has an entry: what it
  does, entry point, usage steps, a check command with expected output, and code and test paths. The planner
  writes the entry text, the implementer adds it, and the verifier follows its steps and fails the run if they are wrong.

## Editing the agents

Each `agents/rpp-*.md` file holds what is unique to that agent. Rules that several agents share (language,
model rule, tests, worktree workspace, report and blockers, the integrator's job) live in `agents/_common/`.
An agent pulls one in with a line `<!-- include: name -->`, and `install.sh` expands it at install time.
Change a shared rule once in `_common/`, then re-run `install.sh`.

## Notes and guarantees

- The supervisor never edits feature code, never merges or pushes itself, never deletes branches, and never
  force-pushes. Only the integrator and `rpp-ci-fixer` push to the target repo, and only the integrator merges a PR (stage 9). Only `rpp-feedback` pushes to this repo.
- Agents write documents, reports, comments, and commit messages in
  [ASD-STE100](https://www.asd-ste100.org/) (Simplified Technical English). The integrator's summary is exempt.
- State, plan, verify files, and reports are in `<repo>/.git/rpp/<run>/`. Worktrees are in `../.rpp-wt-<slug>/`
  and the integrator removes them. The auditor, security, and tidy branches are kept. Dependency symlinks are
  listed in `<repo>/.git/info/exclude`, so they are never committed.
- Agents may not change the model they run on, and the supervisor may not override an agent's model.
  Each step uses the model you chose at install time. To change a model, re-run `install.sh`.

## License

MIT. See [LICENSE](LICENSE).
