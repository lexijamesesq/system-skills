# system-skills

Skills that maintain the estate itself: declared-state capture and apply, laptop sync, and project scaffolding.

Published as the `system` marketplace — one plugin, `system@system`, serving the skills under `skills/`.

```sh
claude plugin marketplace add lexijamesesq/system-skills
claude plugin install system@system
claude plugin enable system@system
```

Releases are cut by CI on push to `main` (`system--v<version>`) whenever `.claude-plugin/plugin.json`'s version is bumped; a PR that changes content without a bump is blocked by `release-check`.

## Shared repository setup skill

`skills/new-repo/SKILL.md` supports both creating a repository and updating its
estate setup. Claude receives it through the existing `system@system` plugin.
For Codex, deliver only this skill from the same reviewed release/revision; the
other skills and marketplace stay unchanged.

Use a durable checkout of that revision as `SYSTEM_SKILLS_CHECKOUT`, not a scratch
checkout or an independently edited copy. Compare its `skills/new-repo/SKILL.md`
hash with the file actually discovered by Claude. Inspect the existing Codex
`${CODEX_HOME:-$HOME/.codex}/skills/new-repo` target before installation: if its
content matches, leave it alone; if it differs or contains unrelated files,
preserve it and resolve the intended replacement explicitly. Do not overwrite it
with a forced link or recursive copy.

When the target is absent, ordinary single-skill delivery is:

```sh
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
ln -s "$SYSTEM_SKILLS_CHECKOUT/skills/new-repo" \
  "${CODEX_HOME:-$HOME/.codex}/skills/new-repo"
```

Confirm both agents discover and read the same reviewed skill bytes, then repeat
the comparison to verify no installation change is needed. Updating the durable
source later requires the matching reviewed release and the same comparison; this
is not automatic marketplace synchronization. Source validation alone does not
prove installed discovery or the skill's real create/update/no-op behavior.
