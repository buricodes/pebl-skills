---
name: run-checks
description: Find and run a project's tests, linter and type checker before saying a coding task is done, then fix what fails. Use at the end of any code change, when the user says "run the checks", "make sure it passes", "is it green", or before committing, opening a pull request or handing work back.
summary: Finds a project's tests, linter and type checker, runs them before the agent says it's done, and fixes what the change broke.
version: 1.0.0
tags: [testing, lint, ci, quality, verification]
use_cases: [make sure a change passes before committing, catch broken tests before a pull request]
docs_url: https://github.com/buricodes/pebl-skills/tree/main/run-checks
---

# Run checks

Don't tell the user a change is finished until the project's own checks pass, or you have said plainly which ones fail and why.

## 1. Find the checks

Run `scripts/detect-checks.sh` from this skill's folder, passing the project root:

```bash
bash scripts/detect-checks.sh .
```

It prints one check per line as `name<TAB>command`, chosen in this order:

1. A `[checks]` section in `pebl.toml` at the root (`test = "..."`, `lint = "..."`), if the project has one.
2. `package.json` scripts `test`, `lint` and `typecheck` (or `type-check`, `check-types`, `tsc`), run with the package manager its lockfile implies. If `node_modules` is missing, an `install` line comes first.
3. `Cargo.toml`: `cargo test`, plus clippy when installed.
4. `go.mod`: `go test ./...` and `go vet ./...`.
5. pytest projects (`pyproject.toml` with `[tool.pytest]`, `pytest.ini` or `conftest.py`), plus ruff and mypy when configured.
6. A `Makefile` with `test`, `lint` or `check` targets.

If it prints nothing, look at the README, `CONTRIBUTING.md`, CI config (`.github/workflows/`) or project instructions for the commands, and ask the user if it is still unclear. Never invent a check that the project doesn't use.

## 2. Run them

Run each command from the project root, one at a time, in the order printed. Give each up to ten minutes. For long output, keep the last 60 lines or so, which is where failures are reported.

## 3. Fix and repeat

For each failure:

1. Read the error and decide whether your change caused it. Compare with `git stash` or the base branch only if you can't tell, and restore your work afterwards.
2. Fix failures your change caused. Fix the code, not the test, unless the test is wrong for the new intended behaviour; say so if you change a test.
3. Run the failed check again, then all of them once more at the end.

Stop after three rounds on the same failure and report it instead of guessing.

## 4. Report

End with one line per check, for example:

```
test       pass   cargo test --quiet
lint       fail   cargo clippy ... (2 warnings in src/net.rs, not from this change)
```

Say which failures existed before your change, if any.

From [pebl](https://github.com/buricodes/pebl), which runs these checks automatically each time a Claude Code session finishes a turn and shows the result in its sidebar.
