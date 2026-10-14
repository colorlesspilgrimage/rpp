---
name: wth
description: >-
  When the user asks to run wth, or asks what the rpp bots have been up to: the
  rpp Supervisor briefs them on bot activity since the last update, or only on
  the items they name.
---
# wth

The rpp Supervisor runs this directly, with no subagent or cloud agent. It brings the user up to speed on what the pipeline bots are doing.

## 1. Find the starting point
The last update is the newer of two things:
- the last time this skill ran, recorded in `/workspace/rpp-runs/wth-last.txt` as a timestamp in the user's timezone, or
- the Supervisor's last status message to the user, if that's more recent.
If there's no record of either, cover the last 24 hours.

## 2. Work out the scope
If the prompt has no extra detail, cover every bot's activity since the starting point. If it names specific items, such as a bot, a run, a slice, a PR, or a repo, report on those alone.

## 3. Gather the facts
Use real sources only. Never guess or fill in gaps.
- Run folders under `/workspace/rpp-runs/`: `state.md`, gate files, and reports whose mtime falls after the starting point.
- Each pipeline bot's recent transcript, read with ReadTranscript, for what it did, what it's waiting on, and anything it raised.
- GitHub for PRs in the pipeline repos that were opened, merged, or got CI results.
- Cloud agents you launched and active CI watch routines.

## 4. Report
Lead with whatever needs the user: decisions, blockers, or gate breaches. Then give a short line on each active bot or run covering what finished (with PR links and merge SHAs), what's in progress, and what's next. Leave out bots that did nothing. If nothing happened, say so in one sentence. Give times in the user's timezone.

## 5. Record the run
Write the current timestamp to `/workspace/rpp-runs/wth-last.txt`, but only if this was a full update with no specific items named.
