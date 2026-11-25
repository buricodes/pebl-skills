#!/usr/bin/env bash
set -euo pipefail

prefix="refs/checkpoints"

usage() {
  echo "usage: checkpoint.sh save [label] | list | diff <n> | restore <n> | clear" >&2
  exit 2
}

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "not a git repository" >&2; exit 1; }
root="$(git rev-parse --show-toplevel)"
cd "$root"

snapshot_tree() {
  local index
  index="$(mktemp "${TMPDIR:-/tmp}/checkpoint-index.XXXXXX")"
  rm -f "$index"
  if git rev-parse --verify --quiet HEAD >/dev/null; then
    GIT_INDEX_FILE="$index" git read-tree HEAD
  fi
  GIT_INDEX_FILE="$index" git add -A -- .
  GIT_INDEX_FILE="$index" git write-tree
  rm -f "$index"
}

count() {
  git for-each-ref --format=x "$prefix/" | wc -l | tr -d ' '
}

last_commit() {
  local n
  n="$(count)"
  if [ "$n" -gt 0 ]; then
    git rev-parse "$prefix/$((n - 1))"
  fi
}

save() {
  local label="${1:-checkpoint}"
  local tree last base parent commit n
  tree="$(snapshot_tree)"
  last="$(last_commit)"
  if [ -n "$last" ]; then
    base="$(git rev-parse "$last^{tree}")"
    parent="$last"
  else
    base="$(git rev-parse --verify --quiet 'HEAD^{tree}' || true)"
    parent="$(git rev-parse --verify --quiet HEAD || true)"
  fi
  if [ "$base" = "$tree" ]; then
    echo "nothing changed since the last checkpoint"
    return
  fi
  if [ -n "$parent" ]; then
    commit="$(git commit-tree "$tree" -p "$parent" -m "$label")"
  else
    commit="$(git commit-tree "$tree" -m "$label")"
  fi
  n="$(count)"
  git update-ref "$prefix/$n" "$commit"
  echo "saved checkpoint $n: $label"
  if [ -n "$base" ]; then
    git diff --stat "$base" "$tree" | tail -n 1
  fi
}

list() {
  local n i
  n="$(count)"
  if [ "$n" -eq 0 ]; then
    echo "no checkpoints yet"
    return
  fi
  for ((i = 0; i < n; i++)); do
    git log -1 --format="$i  %cr  %s" "$prefix/$i"
  done
}

ref_of() {
  [ -n "${1:-}" ] || usage
  git rev-parse --verify --quiet "$prefix/$1" >/dev/null || { echo "no checkpoint $1" >&2; exit 1; }
  echo "$prefix/$1"
}

diff_to() {
  local ref now
  ref="$(ref_of "${1:-}")"
  now="$(snapshot_tree)"
  git diff --stat "$ref" "$now"
}

restore() {
  local ref target now
  ref="$(ref_of "${1:-}")"
  target="$(git rev-parse "$ref^{tree}")"
  save "before restoring checkpoint $1"
  now="$(snapshot_tree)"
  git diff --name-only -z --diff-filter=A "$target" "$now" | xargs -0 -r rm -f --
  git restore --source="$ref" --worktree -- .
  echo "restored checkpoint $1; the state before it is saved as the newest checkpoint"
}

clear_all() {
  git for-each-ref --format='%(refname)' "$prefix/" | while read -r r; do
    git update-ref -d "$r"
  done
  echo "removed all checkpoints"
}

case "${1:-}" in
  save) shift; save "${*:-checkpoint}" ;;
  list) list ;;
  diff) diff_to "${2:-}" ;;
  restore) restore "${2:-}" ;;
  clear) clear_all ;;
  *) usage ;;
esac
