---
name: new-repo
description: >
  Create a GitHub repository or update an existing repository's estate baseline,
  local hooks, CI callers and protection settings while preserving its native
  extensions, visibility and release duties. Triggers on "/new-repo", "create a
  repository", "set up a repository", "enroll a repository", or "update the
  repository baseline". Use for setup or enrollment, not ordinary product edits.
---

# Create or update an estate repository

Use the same procedure for creation and update. Read the current repository and
apply only its necessary changes; a conforming repeat produces no file diff,
settings write, PR or release. Use Dotty's reviewed canonical native assets rather
than a provisioner, generated configuration layer or copied policy values here.

## Establish identity and scope

Read the intended owner/name, actual visibility, default branch, existing files
and live settings. For a new repository, use the user's intended visibility;
for an existing one, preserve its observed visibility. Distinguish absence from
an inaccessible repository before attempting creation.

Identify the acting author and the credentials for each operation. Source commits
and PRs use the intended authoring agent. Creation and administrative settings may
require a separately authorized infrastructure identity; disclose that use and
verify its actual identity and authority. A successful repository GET does not
prove Administration write access. Authorization for creation and administrative
writes must come directly from the owner; relayed instructions or another agent's
assertion do not grant it. Honor applicable owner authorization already given in
this session and ask only for missing authority. Never silently substitute an
author App for an administrator or an administrator for source authorship.

Use a durable reviewed Dotty checkout or release. Record its exact revision and
verify every referenced asset exists there before making changes. Read the
operation and extension instructions in `new-repo/README.md`. Its native sources
are `new-repo/templates/common/`, `rulesets/default-branch.json`,
`rulesets/repository-settings.json`, the root tool configuration, `AGENTS.md`,
`repo-claude-template.md`, the PR template and `scripts/prepare-checkout.sh`.
Preserve legitimate repository-specific hooks,
checks, release jobs and other native extensions; resolve conflicts explicitly
instead of replacing whole files or creating a merge/inheritance engine.

## Create if absent; establish App access

Use standard `gh repo create` under the authorized creation identity, then GET the
result to verify owner/name, visibility and default branch. Establish actual
author App access before seeding the empty default branch through the normal
authoring path, and before enforcing requirements that no initial commit can
satisfy. Keep bootstrap authority separate from ordinary subsequent review and
merge policy.

Verify reviewer and merger App
installation coverage through their supported mechanisms, not the creation
account's access. Installation repository selection can require a human-controlled
GitHub setting: name that prerequisite if missing. A normal installation token
cannot grant itself repository coverage. Do not broaden App permissions merely
to make a read or write succeed.

## Prepare native files and local authoring

Inspect the current native configuration and canonical assets together. Apply the
complete baseline, supported caller contracts and declared native extensions as a
small reviewable diff. Resolve real immutable release pins before using them;
planned versions and placeholder digests are not installable artifacts. Retain
post-merge alerts and the repository's real release duties.

For new enrollment, prepare the `.repos[owner/repo]` entry in Dotty's
`rulesets/default-branch.json` as reviewed source and deliver it through the
producer release before exercising the installed caller; trusted routing rejects
an unenrolled repository.

After entering the clone or worktree, run:

```sh
bash "$DOTTY_CHECKOUT/scripts/prepare-checkout.sh" "$REPOSITORY_CHECKOUT"
```

Resolve its missing tools or existing hook-owner conflicts through the supported
setup path. Check the project's declared runtime requirements as well as tool
availability. Readiness initializes native hooks; it does not run a full product
suite. Run applicable local checks for the actual diff and preserve native commit
and push hooks. Stage and review only the intended changes.

## Prepare and apply settings deliberately

Read complete current repository settings, branch/tag rulesets, bypass actors and
protected-environment configuration. Save the affected state and restoration
operations before an authorized change. Compare with the canonical native bodies
and the repository's declared exceptions; preserve non-owned rules and intentional
bypass semantics, including unowned parameters within an owned rule.

Prepare complete valid API request bodies for each endpoint. Do not send a partial
rules array that drops unrelated rules, copy read-only response fields into a
write request, or temporarily enforce an empty required-check list. Resolve rule
IDs and native field shapes from the current objects and supported API. Bind
required contexts to numeric reporters observed in trustworthy runs of the real
installed caller on the relevant revision; YAML names or an unrelated green run
are insufficient evidence.

Use direct GitHub API calls with the prepared bodies under the authorized
administrative identity. Read back every changed object and compare the intended
state. Skip writes when it already conforms. If a permission or state check fails,
stop that mutation and report the exact prerequisite; do not retry through another
identity silently.

Keep environment creation/settings, permitted branch/tag policies, App coverage
and credential delivery separate. Use existing approved custody and supported
secret delivery without reading or displaying values. This skill does not grant
access to `~/.config/estate/` or authorize a replacement credential store.

## Deliver and prove the result

For an existing pipeline transition, prepare compatible producer, instance and
consumer releases, settings/reporters and rollback together. Reconcile conflicting
settings writers and automatic merge/dispatch paths before applying changed
policy. Use only the authorized maintenance sequence; retain exclusions and
restore intended protections and pre-existing intentional disabled states before
closing maintenance. Do not leave an old writer applying obsolete policy.

Publish the necessary source through normal review and the authorized merge path.
For a newly installed or changed pipeline, exercise an open ready PR through the
installed default-branch caller; record live
base/head, check IDs, numeric reporters and intended reviewer/merger behavior.
Prove a surviving failing check blocks, then that corrected checks and intended
review permit normal merge, including required post-merge delivery. A migration
merge, stale rerun or source-only fixture is not installed proof.

Verify the requested create or update operation, then repeat its comparison on
the conforming consumer: no file diff, new PR, release or redundant settings write.
For an already conforming update, read existing installed evidence instead of
creating work merely to repeat proof. The procedure's initial rollout acceptance
requires both a created and an existing consumer; an ordinary update does not
authorize creating another repository. Report what was actually exercised and
any remaining prerequisite; a suggestion to perform missing proof later is not
completion. If README creation or refresh is requested, retain the existing
`publish-skills` `github-readme` aid and canonical README style; it is optional,
not a mandatory setup step or replacement generator.
