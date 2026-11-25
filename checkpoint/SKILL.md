---
name: checkpoint
description: Save and restore snapshots of the working tree while an agent edits code, without committing, staging or touching HEAD. Use before a risky or large change, when the user says "checkpoint", "save a snapshot", "undo what you just did", "go back to before", or wants to compare the code now with an earlier point.
summary: Save and restore snapshots of your code while an agent edits it, stored as git refs. No commits, no staging, HEAD untouched.
version: 1.0.0
tags: [git, undo, snapshot, checkpoint, safety]
use_cases: [undo an agent's changes, try a risky refactor safely, compare code with an earlier point]
docs_url: https://github.com/buricodes/pebl-skills/tree/main/checkpoint
---

# Checkpoint

Snapshots of every file in the repo (tracked and untracked, respecting `.gitignore`) stored as git refs under `refs/checkpoints/`. They never change HEAD, the branch, the staging area or the commit history, so they are safe to take at any time, even with uncommitted work.

All commands run `scripts/checkpoint.sh` from this skill's folder, inside the user's git repository.

## When to save

1. Before starting a change that touches many files, deletes files, or rewrites something the user cares about.
2. After each step of a multi step task that leaves the code working, with a short label saying what the step did.
3. Whenever the user asks for one.

```bash
bash scripts/checkpoint.sh save "add retry to the http client"
```

If nothing changed since the last checkpoint, nothing is saved.

## Looking back

```bash
bash scripts/checkpoint.sh list
bash scripts/checkpoint.sh diff 2
```

`list` shows each checkpoint's number, age and label. `diff <n>` shows which files differ between checkpoint `n` and the code now. For the full patch, use `git diff refs/checkpoints/<n>`.

## Restoring

```bash
bash scripts/checkpoint.sh restore 2
```

Before restoring, the current state is saved as a new checkpoint, so a restore can always be undone by restoring that one. Files that did not exist at checkpoint `n` are removed; everything else is put back as it was.

Always tell the user which checkpoint you restored and the number of the safety checkpoint taken just before it. Ask before restoring unless the user asked for it directly.

## Cleaning up

```bash
bash scripts/checkpoint.sh clear
```

Removes every checkpoint ref. Only do this when the user asks.

## Notes

1. Requires git and bash. Works in any agent that can run shell commands.
2. Checkpoints are local refs; they are not pushed unless someone pushes `refs/checkpoints/*` on purpose.
3. Ignored files (build output, `node_modules`, `.env`) are not captured or restored.

From [pebl](https://github.com/buricodes/pebl), which takes these snapshots automatically after every Claude Code turn and lets you scrub back through them.
