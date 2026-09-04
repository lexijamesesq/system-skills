---
name: system-blueprint
description: Capture or apply the system blueprint — the canonical declared state for harness-managed config (MCP servers, hooks, plugins, settings sections) that lives at ~/bin/dotty-private/.claude/blueprint/. Triggers on "/system-blueprint", "system blueprint", "capture blueprint", "apply blueprint", "sync with blueprint", or similar phrases.
---

# system-blueprint

**Prerequisite:** this skill requires a dotty-private companion repo with blueprint slice scripts at `~/bin/dotty-private/.claude/blueprint/`. Without it, both subcommands below fail (capture has no slices to refresh; apply has no bootstrap.sh to run). See the project README's Requirements section.

The blueprint is the canonical declared state for harness-managed config that otherwise lives outside git. Each blueprint slice script declares one orthogonal slice of that state and implements three verbs: apply, describe, capture.

## Subcommands

### `/system-blueprint capture <type>`

Refresh blueprint slices of the given type from this device's live state.

```bash
for slice in ~/bin/dotty-private/.claude/blueprint/<type>-*.sh ~/bin/dotty-private/.claude/blueprint/<type>.sh; do
  [[ -f "$slice" ]] && bash "$slice" capture
done
```

Workflow:
1. Glob `<type>-*.sh` and `<type>.sh` in the blueprint directory
2. For each match, run `bash slice capture`
3. Report what was captured
4. Suggest `cd ~/bin/dotty-private && git diff blueprint/ && git commit -m "..."` for review

Does NOT commit. The user reviews via git diff and commits at their own boundary so they can batch with other dotty-private edits if desired.

### `/system-blueprint apply [--prune]`

Apply all blueprint slices to the current device.

```bash
bash ~/bin/dotty-private/.claude/blueprint/bootstrap.sh [--prune]
```

- Default: additive — add missing, update changed, leave undeclared alone
- `--prune`: full reconcile — slices remove items in live state but not declared

## Slice contract (for authoring new slice types)

Every slice script in `blueprint/` must implement three verbs:

| Verb | Behavior |
|---|---|
| `apply` (default) | Additive reconciliation against this slice's state class. `--prune` flag enables full reconcile. |
| `describe` | Print declared state as JSON to stdout. Format is type-specific; consumers (Claude during point-of-use reasoning) handle interpretation. |
| `capture` | Read live state for this slice's class+scope, write to sibling `.json` data file, append CHANGELOG stub. |

Naming convention:
- `<type>-<scope>.sh` for profile-scoped state (e.g. `mcp-personal.sh`, `settings-professional.sh`)
- `<type>.sh` for global state (e.g. `plugins.sh`)

Each slice colocates its declared state in a sibling `.json` (or, for a few slices, a plain text/markdown) file with the same basename. **`capture` is not one universal direction** — check a slice's own header before assuming: some slices' `capture` writes the declaration from live state (`core`, `mcp-personal`, `mcp-professional`, `settings-personal`, `settings-professional`, `update-mbp-exclusions`); most are report-only, a one-directional drift check that never writes the declared file back (`rosters`, `qa-private-vocab`, `gitleaks-rules`, `statusline`, `traffic-cone-shim`, `brewfile`, `ways-of-working`, `claude-md`, `metrics-config`, `tools`, `plugins`, `op-agent`).

## Files

- `~/bin/dotty-private/.claude/blueprint/bootstrap.sh` — composition: runs every slice below in apply mode, in the order it lists them
- `~/bin/dotty-private/.claude/blueprint/CHANGELOG.md` — narrative log of captures
- `~/bin/dotty-private/.claude/blueprint/<slice>.sh` (+ a sibling declared-state file for most slices) — one script per slice

## Coverage

18 slices, per `bootstrap.sh`'s own `SLICES` array (that array is authoritative — this list mirrors it, not the reverse):

- `op-agent.sh` — the 1Password service-account wrapper scripts, installed to a fixed path
- `plugins.sh` — per-profile plugin marketplaces + enabled plugins (`plugins.json`); the shared plugin cache's install lane
- `statusline.sh` — the statusline script, real file at both profiles' fixed path (not plugin-carriable — see [[estate-substrate-architecture]])
- `traffic-cone-shim.sh` — the `~/.local/bin/traffic-cone` PATH shim into the installed `core` plugin's cache copy
- `core.sh` — profile skeleton for `skills/`/`agents/` per-entry symlinks; both profiles declare `{}` for both surfaces today (the harness now serves skills/agents/hooks from plugins, not symlinks) — the slice stays live in case a future surface needs the mechanism, but has nothing to enact right now
- `settings-personal.sh`, `settings-professional.sh` — each profile's real `settings.json` (hooks, env, statusLine, extraKnownMarketplaces, a hand-curated `permissions.allow` floor `capture` never overwrites)
- `ways-of-working.sh` — the always-on public rule, pinned to a released dotty tag, installed as a real file under each profile's `rules/` directory on the machine (not tracked in this repo)
- `claude-md.sh` — the global CLAUDE.md, real file at both profiles' `CLAUDE.md`
- `brewfile.sh` — Homebrew formula versions vs. what each repo's CI pins to (status-only)
- `gitleaks-rules.sh` — the gitleaks operator rules, real file at `~/.config/gitleaks/operator-rules.toml`
- `rosters.sh` — the PII tag-taxonomy rosters, real file at `~/.config/estate/tag-taxonomy-rosters.md`
- `qa-private-vocab.sh` — the private QA vocabulary, real file at `~/.config/estate/qa-private-vocab.md`
- `metrics-config.sh` — Metrics project config files, written into that repo's own checkout (the one slice that writes inside a working tree — justified in its own header)
- `update-mbp-exclusions.sh` — the Mini→laptop exclusions list, real file at `~/.config/estate/update-mbp-exclusions.txt`
- `tools.sh` — external tool installations (mcpvault, linear-tactic, op, op-sa, snow, obsidian)
- `mcp-personal.sh` — MCP servers in the personal profile's Claude Code config file on the machine
- `mcp-professional.sh` — symlink to mcp-personal.sh (derives profile from filename)

Two more scripts live in the same directory but are not `bootstrap.sh` slices: `verify.sh` (post-apply reference-resolution check for `op://` refs, run by `bootstrap.sh` after every slice) and `blueprint-evals.sh` (the slice test harness).

## Related

- `${CLAUDE_PLUGIN_ROOT}/skills/update-mbp/SKILL.md` — pre-travel MBP sync (this plugin's sibling skill) that includes a blueprint-apply lane after dotty-private pull
