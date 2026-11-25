---
name: second-opinion-review
description: Review uncommitted or branch changes with fresh eyes, read only, and return findings as path:line comments. Use when the user asks for a review, a second opinion, "check what the other agent did", "is this ready to merge", or before committing or opening a pull request.
summary: A read only code review of the current diff with fresh eyes, ending in path:line findings the author can act on.
version: 1.0.0
tags: [code review, git, pull request, quality, bugs]
use_cases: [review another agent's work, check a branch before merging, second opinion on a diff]
docs_url: https://github.com/buricodes/pebl-skills/tree/main/second-opinion-review
---

# Second opinion review

Act as a reviewer who did not write this code. The goal is a short list of concrete problems the author can act on, not a summary of the change.

## Rules

1. Read only. Don't change, create or delete any files, don't stage, and don't commit, even if a fix looks trivial. Put fixes in your findings.
2. Judge the change against the task it was meant to do. If the user didn't say what the task was, work it out from the branch name, commit messages and the diff, and say what you assumed.

## 1. Find the change

Pick the first that applies:

1. The user named a base (a branch, commit or pull request): `git diff <base>...HEAD` plus any uncommitted changes.
2. There are uncommitted changes: `git diff HEAD` and `git status`.
3. Otherwise, the current branch against its merge base with the default branch: `git diff $(git merge-base HEAD origin/HEAD)...HEAD`, falling back to `main` or `master`.

Read new, untracked files directly; they are not in the diff. Open the surrounding code for anything the diff alone doesn't explain.

## 2. Look for

1. Does it do what the task asks, completely? Anything missing or only half done?
2. Bugs: wrong conditions, off by one, null or empty cases, error paths that are swallowed, races, wrong units, broken callers of a changed function.
3. Risky changes: data deletion, migrations, security (injection, secrets, auth checks), behaviour changes that the task didn't ask for.
4. Tests: new behaviour with no test, tests that can't fail, tests changed to match a bug.
5. Project rules in `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md` or similar that the change breaks.

Skip style nits a formatter or linter would catch, and don't pad the list. Three real findings beat ten weak ones.

## 3. Report

Start with one or two sentences on whether the change is ready. Then end your reply with a fenced block marked `review`, one finding per line as `path:line: what is wrong and what to do`, using line numbers from the new version of the file:

```review
src/cart.ts:42: total() returns undefined when the cart is empty; return 0 instead
src/cart.test.ts:10: no test for removing the last item; add one
```

If nothing needs changing, say so and end with an empty `review` block. The fixed format lets the author, or another agent, take the findings one at a time.

From [pebl](https://github.com/buricodes/pebl), where pressing R on a session starts this reviewer next to the author and loads its findings into a review popup you can edit and send back.
