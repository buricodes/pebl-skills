#!/usr/bin/env bash
set -uo pipefail

dir="${1:-.}"
cd "$dir" || exit 1

if [ -f pebl.toml ] && grep -q '^\[checks\]' pebl.toml; then
  awk '/^\[checks\]/{on=1; next} /^\[/{on=0} on && /=/' pebl.toml \
    | grep -v '^auto_fix' \
    | sed -E 's/^[[:space:]]*([A-Za-z0-9_-]+)[[:space:]]*=[[:space:]]*"(.*)"[[:space:]]*$/\1\t\2/'
  exit 0
fi

if [ -f package.json ]; then
  pm=npm
  [ -f pnpm-lock.yaml ] && pm=pnpm
  [ -f yarn.lock ] && pm=yarn
  { [ -f bun.lock ] || [ -f bun.lockb ]; } && pm=bun
  if [ ! -d node_modules ]; then
    printf 'install\t%s install\n' "$pm"
  fi
  script() {
    node -e 'const s=(require("./package.json").scripts||{});const v=s[process.argv[1]];process.exit(v&&!v.includes("no test specified")?0:1)' "$1" 2>/dev/null
  }
  if script test; then
    if [ "$pm" = bun ]; then printf 'test\tbun run test\n'; else printf 'test\t%s test\n' "$pm"; fi
  fi
  script lint && printf 'lint\t%s run lint\n' "$pm"
  for t in typecheck type-check check-types tsc; do
    if script "$t"; then printf 'typecheck\t%s run %s\n' "$pm" "$t"; break; fi
  done
  exit 0
fi

if [ -f Cargo.toml ]; then
  printf 'test\tcargo test --quiet\n'
  command -v cargo-clippy >/dev/null 2>&1 && printf 'lint\tcargo clippy --all-targets --quiet -- -D warnings\n'
  exit 0
fi

if [ -f go.mod ]; then
  printf 'test\tgo test ./...\n'
  printf 'vet\tgo vet ./...\n'
  exit 0
fi

if grep -qs '\[tool.pytest' pyproject.toml || [ -f pytest.ini ] || [ -f conftest.py ] || [ -f tests/conftest.py ]; then
  printf 'test\tpython -m pytest -q\n'
  grep -qs '\[tool.ruff' pyproject.toml && printf 'lint\truff check .\n'
  grep -qs '\[tool.mypy' pyproject.toml && printf 'typecheck\tmypy .\n'
  exit 0
fi

if [ -f Makefile ]; then
  for t in test lint check; do
    grep -q "^$t:" Makefile && printf '%s\tmake %s\n' "$t" "$t"
  done
fi
exit 0
