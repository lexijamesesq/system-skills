#!/usr/bin/env bash
# release-dotty.eval.sh — acceptance evals for the three fixes this script
# carries: the tag is created via the GitHub API as the Claude App (never a
# local `git tag` + handoff push), the PR-exists check uses an open-state
# list instead of `gh pr view <branch>` (which resolves to the most recent
# PR regardless of state), and the consumer bump operates on a scratch clone
# instead of a discovered local checkout or worktree.
#
# Fully offline: `gh` and `pre-commit` are stubbed on PATH so nothing here
# ever reaches a real network. The stubbed `gh api` performs the equivalent
# real git plumbing against a local bare "dotty" remote (creates a real
# annotated tag object, pushes a real ref) so ls-remote-based verification
# in the script under test is genuine, not assumed.
#
# Run: bash release-dotty.eval.sh (from this directory, or any cwd — paths
# are resolved relative to this file).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/release-dotty.sh"
[[ -x "$SCRIPT" ]] || { echo "FATAL: $SCRIPT not executable"; exit 2; }

# The script under test makes real commits inside its own scratch clones
# (that's the whole point of fix 3) -- a bare CI runner has no global git
# identity configured at all, unlike a real machine running this for real.
# Env-var overrides, not `git config --global`, so running this eval
# locally never touches a developer's own global git identity.
export GIT_AUTHOR_NAME="release-dotty eval" GIT_AUTHOR_EMAIL="release-dotty-eval@example.invalid"
export GIT_COMMITTER_NAME="release-dotty eval" GIT_COMMITTER_EMAIL="release-dotty-eval@example.invalid"

passed=0
failed=0
check() { # <rc> <label> [detail]
  if [[ "$1" == "0" ]]; then
    passed=$((passed + 1)); echo "  OK: $2"
  else
    failed=$((failed + 1)); echo "  FAIL: $2"
    [[ -n "${3:-}" ]] && echo "        $3"
  fi
}

# ---- fake `gh`: routes api/release/pr subcommands, no network ever -------
make_fake_gh() { # <bin-dir> <call-log-file>
  local bin="$1" log="$2"
  cat > "$bin/gh" <<STUB
#!/usr/bin/env bash
set -uo pipefail
LOG="$log"
get_field() { # <flag-list-varname-unused> <key> <argv...>
  local key="\$1"; shift
  local a
  for a in "\$@"; do
    case "\$a" in "\$key="*) printf '%s' "\${a#"\$key"=}"; return 0 ;; esac
  done
}
case "\$1" in
  api)
    shift
    endpoint="\$1"; shift
    args=("\$@")
    if [[ "\$endpoint" == */git/tags ]]; then
      tag="\$(get_field tag "\${args[@]}")"
      message="\$(get_field message "\${args[@]}")"
      object="\$(get_field object "\${args[@]}")"
      git tag -a "\$tag" -m "\$message" "\$object" >/dev/null
      sha="\$(git rev-parse "refs/tags/\$tag")"
      echo "api-tags \$tag" >> "\$LOG"
      echo "\$sha"
    elif [[ "\$endpoint" == */git/refs ]]; then
      ref="\$(get_field ref "\${args[@]}")"
      tagname="\${ref#refs/tags/}"
      git push --quiet origin "refs/tags/\$tagname"
      echo "api-refs \$tagname" >> "\$LOG"
    else
      echo "fake gh api: unhandled endpoint \$endpoint" >&2; exit 1
    fi
    ;;
  release)
    shift
    sub="\$1"; shift
    case "\$sub" in
      view)
        tag="\$1"
        echo "release-view \$tag" >> "\$LOG"
        [[ -f "\$RELEASE_MARKER_DIR/\$tag" ]]
        ;;
      create)
        tag="\$1"
        echo "release-create \$tag" >> "\$LOG"
        touch "\$RELEASE_MARKER_DIR/\$tag"
        ;;
    esac
    ;;
  pr)
    shift
    sub="\$1"; shift
    case "\$sub" in
      list)
        echo "pr-list" >> "\$LOG"
        jqexpr=""
        args=("\$@")
        for ((i=0; i<\${#args[@]}; i++)); do
          [[ "\${args[i]}" == "--jq" ]] && jqexpr="\${args[i+1]}"
        done
        raw=""
        if [[ -f "\$PR_OPEN_MARKER" ]]; then
          raw="[{\"number\":\$(cat "\$PR_OPEN_MARKER")}]"
        else
          raw="[]"
        fi
        if [[ -n "\$jqexpr" ]]; then
          printf '%s' "\$raw" | jq -r "\$jqexpr"
        else
          printf '%s' "\$raw"
        fi
        ;;
      create)
        echo "pr-create \$*" >> "\$LOG"
        echo "42" > "\$PR_OPEN_MARKER"
        echo "https://example.invalid/pr/42"
        ;;
      view)
        echo "pr-view \$*" >> "\$LOG"
        exit 1
        ;;
    esac
    ;;
  *)
    echo "fake gh: unhandled \$*" >&2; exit 1 ;;
esac
STUB
  chmod +x "$bin/gh"
}

# jq's own --jq handling inside the fake gh above is a shell case match on
# the endpoint, not a real jq pipe -- the script's own `--jq '.sha'` /
# `--jq '.[0].number // empty'` flags are simply ignored args the fake
# consumes and never interprets, since the fake gh prints exactly the bare
# value the real jq expression would have extracted. Confirm real jq is
# still present, since pre-commit and other real tooling need it.
command -v jq >/dev/null 2>&1 || { echo "FATAL: jq required"; exit 2; }

make_fake_precommit() { # <bin-dir> <target-tag>
  local bin="$1" target="$2"
  cat > "$bin/pre-commit" <<STUB
#!/usr/bin/env bash
set -uo pipefail
if [[ "\$1" == "autoupdate" ]]; then
  sed -i.bak -E "s#(repo: https://github.com/lexijamesesq/dotty\$)#\\1#" .pre-commit-config.yaml
  python3 - "\$PWD/.pre-commit-config.yaml" "$target" <<'PY'
import sys
path, target = sys.argv[1], sys.argv[2]
lines = open(path).read().splitlines(keepends=True)
out = []
in_dotty = False
for line in lines:
    if "repo: https://github.com/lexijamesesq/dotty" in line:
        in_dotty = True
        out.append(line)
        continue
    if in_dotty and "rev:" in line:
        indent = line[:len(line) - len(line.lstrip())]
        out.append(f"{indent}rev: {target}\n")
        in_dotty = False
        continue
    out.append(line)
open(path, "w").writelines(out)
PY
  rm -f .pre-commit-config.yaml.bak
  exit 0
fi
exit 0
STUB
  chmod +x "$bin/pre-commit"
}

# make_dotty_fixture -> prints a fresh scratch root with:
#   <root>/dotty-remote.git   (bare — the "origin" every clone points at)
#   <root>/dotty-checkout     ($DOTTY arg — clean, on main, matching origin)
make_dotty_fixture() {
  local root remote checkout
  root="$(mktemp -d)"
  remote="$root/dotty-remote.git"
  checkout="$root/dotty-checkout"
  git init --quiet --bare -b main "$remote"
  git clone --quiet "$remote" "$checkout"
  git -C "$checkout" config user.email "t@example.com"
  git -C "$checkout" config user.name "t"
  mkdir -p "$checkout/git-hooks"
  echo "hooks: []" > "$checkout/.pre-commit-hooks.yaml"
  echo "# fixture" > "$checkout/git-hooks/x.sh"
  git -C "$checkout" add .
  git -C "$checkout" commit --quiet -m "seed"
  git -C "$checkout" push --quiet origin main
  printf '%s\n' "$root"
}

# make_consumer_fixture <root> <name> <dotty-pin-line> -> prints the bare
# remote path; also leaves a local checkout for discovery at <root>/<name>.
make_consumer_fixture() {
  local root="$1" name="$2" pin="$3" remote checkout
  remote="$root/${name}-remote.git"
  checkout="$root/$name"
  git init --quiet --bare -b main "$remote"
  git clone --quiet "$remote" "$checkout"
  git -C "$checkout" config user.email "t@example.com"
  git -C "$checkout" config user.name "t"
  cat > "$checkout/.pre-commit-config.yaml" <<CFG
repos:
  - repo: https://github.com/lexijamesesq/dotty
    rev: $pin
    hooks:
      - id: gitleaks-staged
CFG
  git -C "$checkout" add .pre-commit-config.yaml
  git -C "$checkout" commit --quiet -m "seed"
  git -C "$checkout" push --quiet origin main
  printf '%s\n' "$remote"
}

# ---- 1. tag creation via the API, verified, no local-tag-then-exit -------
t_tag_via_api() {
  local root dotty bin log out
  root="$(make_dotty_fixture)"
  dotty="$root/dotty-checkout"
  bin="$root/bin"; mkdir -p "$bin" "$root/releases" "$root/home/bin" "$root/home/Agents" "$root/home/Repos"
  make_fake_gh "$bin" "$root/calls.log"
  make_fake_precommit "$bin" "unused"

  out="$(PATH="$bin:$PATH" HOME="$root/home" RELEASE_MARKER_DIR="$root/releases" PR_OPEN_MARKER="$root/pr-open" bash "$SCRIPT" "$dotty" 2>&1)"
  rc=0; [[ "$out" == *"Tagged and pushed"* ]] || rc=1
  check "$rc" "tag: script reports it tagged and pushed via the API" "$out"

  rc=0; grep -q '^api-tags ' "$root/calls.log" 2>/dev/null || rc=1
  check "$rc" "tag: gh api .../git/tags was called"

  rc=0; grep -q '^api-refs ' "$root/calls.log" 2>/dev/null || rc=1
  check "$rc" "tag: gh api .../git/refs was called"

  local tagname
  tagname="$(grep '^api-tags ' "$root/calls.log" | head -1 | awk '{print $2}')"
  rc=0; [[ -n "$tagname" ]] && git -C "$dotty" ls-remote --exit-code --tags origin "refs/tags/$tagname" >/dev/null 2>&1 || rc=1
  check "$rc" "tag: the ref genuinely exists on the fixture remote (not just claimed)" "tag=$tagname"

  rc=0; grep -q "^release-create $tagname\$" "$root/calls.log" || rc=1
  check "$rc" "tag: the Release was cut for the same tag" "$(cat "$root/calls.log")"

  # Re-entry: run again -- must skip tag creation entirely (no new api-tags
  # call) and only check the Release (already exists -> release-view, no
  # release-create).
  : > "$root/calls.log"
  out="$(PATH="$bin:$PATH" HOME="$root/home" RELEASE_MARKER_DIR="$root/releases" PR_OPEN_MARKER="$root/pr-open" bash "$SCRIPT" "$dotty" 2>&1)"
  rc=0; [[ "$out" == *"RE-ENTRY"* ]] || rc=1
  check "$rc" "tag: re-run recognizes RE-ENTRY" "$out"
  rc=0; grep -q '^api-tags ' "$root/calls.log" && rc=1 || rc=0
  check "$rc" "tag: re-run does NOT create a second tag"
  rc=0; grep -q "^release-view $tagname\$" "$root/calls.log" || rc=1
  check "$rc" "tag: re-run still checks the Release" "$(cat "$root/calls.log")"

  rm -rf "$root"
}

# ---- 2. PR-exists check: open-state list, not `gh pr view <branch>` ------
t_pr_open_check() {
  local root dotty bin log consroot cons_remote out
  root="$(make_dotty_fixture)"
  dotty="$root/dotty-checkout"
  bin="$root/bin"; mkdir -p "$bin" "$root/releases"
  make_fake_gh "$bin" "$root/calls.log"

  consroot="$root/home/Repos"; mkdir -p "$consroot" "$root/home/bin" "$root/home/Agents"
  cons_remote="$(make_consumer_fixture "$consroot" "widget" "v2020.01.01")"
  make_fake_precommit "$bin" "TARGETTAG"

  # No open PR on record (simulates: a merged PR exists from a prior cycle,
  # but nothing open) -- the fix's whole point is that this must still
  # create a new one instead of assuming "gh pr view succeeded" means done.
  out="$(PATH="$bin:$PATH" HOME="$root/home" RELEASE_MARKER_DIR="$root/releases" PR_OPEN_MARKER="$root/pr-open" bash "$SCRIPT" "$dotty" 2>&1)"

  rc=0; grep -q '^pr-list$' "$root/calls.log" || rc=1
  check "$rc" "pr: script lists open PRs rather than viewing by branch name" "$out"

  rc=0; grep -q '^pr-view' "$root/calls.log" && rc=1 || rc=0
  check "$rc" "pr: script never calls the stale-resolving \`gh pr view <branch>\`"

  rc=0; grep -q '^pr-create' "$root/calls.log" || rc=1
  check "$rc" "pr: a PR is actually created when none is open" "$(cat "$root/calls.log")"

  rc=0; grep -q -- '--reviewer lexijamesesq' "$root/calls.log" || rc=1
  check "$rc" "pr: opened with the operator as reviewer"

  # Second run: now an open PR is on record -- must NOT create a second one.
  : > "$root/calls.log"
  # widget's rev is still the old pin locally (script only committed in its
  # scratch clone, never touched the discovery checkout) -- confirms fix 3
  # in passing, checked properly in t_worktree_safety below.
  out="$(PATH="$bin:$PATH" HOME="$root/home" RELEASE_MARKER_DIR="$root/releases" PR_OPEN_MARKER="$root/pr-open" bash "$SCRIPT" "$dotty" 2>&1)"
  rc=0; grep -q '^pr-create' "$root/calls.log" && rc=1 || rc=0
  check "$rc" "pr: second run with an open PR on record does not create another" "$(cat "$root/calls.log")"

  rm -rf "$root"
}

# ---- 3. worktree safety: multiple linked worktrees, none ever switched ---
t_worktree_safety() {
  local root dotty bin consroot cons_remote wt_main wt_ticket out
  root="$(make_dotty_fixture)"
  dotty="$root/dotty-checkout"
  bin="$root/bin"; mkdir -p "$bin" "$root/releases"
  make_fake_gh "$bin" "$root/calls.log"
  make_fake_precommit "$bin" "unused"

  consroot="$root/home/Agents"; mkdir -p "$consroot" "$root/home/bin" "$root/home/Repos"
  cons_remote="$(make_consumer_fixture "$consroot" "hazel" "v2020.01.01")"
  rm -rf "$consroot/hazel"  # the plain checkout above was only to seed content; use worktrees instead

  # A bare-off-nothing local clone that OWNS the worktrees (mirrors hazel's
  # real shape: several linked worktrees sharing one .git, none of them the
  # bare remote itself).
  git clone --quiet "$cons_remote" "$root/hazel-origin-clone"
  wt_main="$consroot/hazel/dev"
  wt_ticket="$consroot/hazel/worktrees/feature-999"
  mkdir -p "$consroot/hazel"
  git -C "$root/hazel-origin-clone" worktree add --quiet -b main-wt "$wt_main" main >/dev/null 2>&1 || \
    git -C "$root/hazel-origin-clone" worktree add --quiet "$wt_main" main
  git -C "$root/hazel-origin-clone" worktree add --quiet -b feature-shared-channel "$wt_ticket" main

  # Real, uncommitted-nowhere-else work sitting in the ticket worktree --
  # the exact shape of the incident this fix closes.
  echo "in-progress substrate work" > "$wt_ticket/substrate.txt"
  git -C "$wt_ticket" add substrate.txt
  git -C "$wt_ticket" config user.email "t@example.com"
  git -C "$wt_ticket" config user.name "t"
  git -C "$wt_ticket" commit --quiet -m "in-progress substrate work, not yet pushed anywhere else"
  local ticket_sha
  ticket_sha="$(git -C "$wt_ticket" rev-parse HEAD)"

  out="$(PATH="$bin:$PATH" HOME="$root/home" RELEASE_MARKER_DIR="$root/releases" PR_OPEN_MARKER="$root/pr-open" bash "$SCRIPT" "$dotty" 2>&1)"

  rc=0; [[ "$(git -C "$wt_ticket" rev-parse --abbrev-ref HEAD)" == "feature-shared-channel" ]] || rc=1
  check "$rc" "worktree: the ticket worktree's branch was never switched" "$out"

  rc=0; [[ "$(git -C "$wt_ticket" rev-parse HEAD)" == "$ticket_sha" ]] || rc=1
  check "$rc" "worktree: the ticket worktree's commit is exactly what it was before"

  rc=0; [[ -z "$(git -C "$wt_ticket" status --porcelain)" ]] || rc=1
  check "$rc" "worktree: the ticket worktree's working tree is still clean"

  rc=0; [[ "$(git -C "$wt_main" rev-parse --abbrev-ref HEAD)" == "main-wt" || "$(git -C "$wt_main" rev-parse --abbrev-ref HEAD)" == "main" ]] || rc=1
  check "$rc" "worktree: the main worktree's branch was never switched either"

  # The bump itself must still have genuinely happened -- on the remote,
  # via a scratch clone, never touching either worktree.
  rc=0; git -C "$root/hazel-origin-clone" ls-remote --exit-code --heads origin dotty-bump >/dev/null 2>&1 || rc=1
  check "$rc" "worktree: the bump branch was still pushed to the remote (scratch-clone path worked)"

  rm -rf "$root"
}

# ---- 4. due-check: the Actions-workflow export class counts too ----------
# Same release channel, two export classes (LEX-755): a change to
# .github/workflows/estate-*.yml or .github/actions/** must make a release
# due, exactly like a pre-commit-hook export change already did; a change
# to neither class (docs-only) must still report nothing to release.
t_due_check_workflow_export() {
  local root dotty bin out first_tag
  root="$(make_dotty_fixture)"
  dotty="$root/dotty-checkout"
  bin="$root/bin"; mkdir -p "$bin" "$root/releases" "$root/home/bin" "$root/home/Agents" "$root/home/Repos"
  make_fake_gh "$bin" "$root/calls.log"
  make_fake_precommit "$bin" "unused"

  # First run: nothing tagged yet, so this always cuts a tag regardless of
  # export class -- just establishes LAST_TAG for the due-check below.
  out="$(PATH="$bin:$PATH" HOME="$root/home" RELEASE_MARKER_DIR="$root/releases" PR_OPEN_MARKER="$root/pr-open" bash "$SCRIPT" "$dotty" 2>&1)"
  first_tag="$(grep '^api-tags ' "$root/calls.log" | head -1 | awk '{print $2}')"
  [[ -n "$first_tag" ]] || { check 1 "due-check: setup — first run produced a tag" "$out"; rm -rf "$root"; return; }
  git -C "$dotty" fetch --quiet origin --tags

  # A workflow-only change: no pre-commit-hooks.yaml/git-hooks/ touched.
  mkdir -p "$dotty/.github/workflows" "$dotty/.github/actions"
  echo "name: Estate CI" > "$dotty/.github/workflows/estate-ci.yml"
  git -C "$dotty" add .github/workflows/estate-ci.yml
  git -C "$dotty" commit --quiet -m "workflow export change"
  git -C "$dotty" push --quiet origin main

  : > "$root/calls.log"
  out="$(PATH="$bin:$PATH" HOME="$root/home" RELEASE_MARKER_DIR="$root/releases" PR_OPEN_MARKER="$root/pr-open" bash "$SCRIPT" "$dotty" 2>&1)"
  rc=0; [[ "$out" != *"nothing to release"* ]] || rc=1
  check "$rc" "due-check: a workflow-only change (.github/workflows/estate-ci.yml) is due" "$out"
  rc=0; grep -q '^api-tags ' "$root/calls.log" || rc=1
  check "$rc" "due-check: the workflow-only change actually cut a new tag" "$(cat "$root/calls.log")"

  rm -rf "$root"
}

t_due_check_docs_only_not_due() {
  local root dotty bin out first_tag
  root="$(make_dotty_fixture)"
  dotty="$root/dotty-checkout"
  bin="$root/bin"; mkdir -p "$bin" "$root/releases" "$root/home/bin" "$root/home/Agents" "$root/home/Repos"
  make_fake_gh "$bin" "$root/calls.log"
  make_fake_precommit "$bin" "unused"

  out="$(PATH="$bin:$PATH" HOME="$root/home" RELEASE_MARKER_DIR="$root/releases" PR_OPEN_MARKER="$root/pr-open" bash "$SCRIPT" "$dotty" 2>&1)"
  first_tag="$(grep '^api-tags ' "$root/calls.log" | head -1 | awk '{print $2}')"
  [[ -n "$first_tag" ]] || { check 1 "due-check: setup — first run produced a tag" "$out"; rm -rf "$root"; return; }
  git -C "$dotty" fetch --quiet origin --tags

  # Docs-only: neither export class touched.
  echo "# notes" > "$dotty/README.md"
  git -C "$dotty" add README.md
  git -C "$dotty" commit --quiet -m "docs only"
  git -C "$dotty" push --quiet origin main

  : > "$root/calls.log"
  out="$(PATH="$bin:$PATH" HOME="$root/home" RELEASE_MARKER_DIR="$root/releases" PR_OPEN_MARKER="$root/pr-open" bash "$SCRIPT" "$dotty" 2>&1)"
  rc=0; [[ "$out" == *"nothing to release"* ]] || rc=1
  check "$rc" "due-check: a docs-only change (README.md) is NOT due" "$out"
  rc=0; grep -q '^api-tags ' "$root/calls.log" && rc=1 || rc=0
  check "$rc" "due-check: the docs-only change did not cut a tag"

  rm -rf "$root"
}

echo "== release-dotty evals =="
t_tag_via_api
t_pr_open_check
t_worktree_safety
t_due_check_workflow_export
t_due_check_docs_only_not_due

echo
if [[ "$failed" == "0" ]]; then
  echo "release-dotty evals: PASS ($passed/$((passed + failed)))"
else
  echo "release-dotty evals: FAIL ($passed/$((passed + failed)))"
  exit 1
fi
