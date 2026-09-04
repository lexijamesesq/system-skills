# system-skills

Skills that maintain the estate itself: declared-state capture and apply, laptop sync, project scaffolding, and dotty's release step.

Published as the `system` marketplace — one plugin, `system@system`, serving the skills under `skills/`.

```
claude plugin marketplace add lexijamesesq/system-skills
claude plugin install system@system
claude plugin enable system@system
```

Releases are cut by CI on push to `main` (`system--v<version>`) whenever `.claude-plugin/plugin.json`'s version is bumped; a PR that changes content without a bump is blocked by `release-check`.
