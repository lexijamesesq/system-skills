---
name: new-project
description: >
  Triggers when the user says "create a new project", "new project",
  "set up a project", "new hub", "/new-project", or similar
  project/hub creation requests.
---

# New Project Setup

Interactive protocol for creating a new Claude-managed project or hub. Walk through each step with the user, gathering answers before creating anything.

## Templates

Read the appropriate template before generating any files:

- **Project:** path configured in global CLAUDE.md > Configuration > `templates.project`
- **Hub:** path configured in global CLAUDE.md > Configuration > `templates.hub`

These templates define the current required structure. Read them at runtime to pick up any changes — do not rely on memorized structure.

## Step 1: Determine Type

Ask the user:

> Is this a **Project** or a **Hub**?
>
> - **Project** = Active work with state tracking (Re-entry Cue, blockers, decisions; queue lives in Linear)
> - **Hub** = Organizes related subprojects, no state of its own

If Hub, skip Steps 3, 4, and 5 (those are project-only).

## Step 2: Gather Core Info

Ask the user for:

1. **Name** — Used for the folder name and the `{name-kebab}` slug (Linear project, paths). Folder uses Mac-style naming (spaces, capitalization); the slug is kebab-case.
2. **Parent location** — Where in the vault hierarchy? Common locations:
   - `{workspace_root}/Projects/` (every live project; the default)
   - Or a hub folder under it (e.g., `{workspace_root}/Projects/Agents/`)

   Where `{workspace_root}` is configured in global CLAUDE.md > Configuration > `workspace_root`.
3. **Description** — 1-3 sentences: "What This Project Is." This goes in the `description` frontmatter field; the template body has no description paragraph (the H1 and the Intent sections carry the rest).
4. **Linear team** — All projects use the team UUID configured in global CLAUDE.md > Configuration > `linear.team_lex_id`.

## Step 3: Create Linear Project (Projects Only)

Call `linear_createProject` with:

- `name`: the project name from Step 2
- `teamIds`: a single-element array containing the team UUID resolved from global CLAUDE.md > Configuration > `linear.team_lex_id`.
- `description`: the short description from Step 2
- `content`: optional expanded content if the user provided additional context

Capture the returned project URL and UUID. Both will be placed in the CLAUDE.md frontmatter as `linear_url` and `linear_project_id`.

## Step 4: Routing Setup (Projects Only)

Linear project ID and URL are already in frontmatter from Step 3 — tasks are routable by default. Linear creates the project in its default state (Backlog); if work starts now, move it to the active state in Linear. No `Context/` folder: rich context lives in `Knowledge/`.

### 4a. Knowledge

Ask the user:

> Will this project accumulate durable reference material across sessions — architectural explanations, research spikes, procedures, posture assessments? (See the "Knowledge Folder (Optional)" section in the project template for when to adopt.)

If **yes:**

- Create a `Knowledge/` directory
- Scaffold the **orientation hierarchy** from the project template's "Orientation hierarchy" section (`templates.project`) — read the overview skeleton there at runtime and create it, filling the blanks with the project's name and `{today}`:
  - `overview.md` — at the **project root**: the 30,000ft page (what the project is, how work moves, an empty area map + the "what counts as an area" guide, house rules carrying the three-hop navigation contract).
  - `Knowledge/Methods/`, `Knowledge/Reference/`, `Knowledge/Research/`, `Knowledge/Decisions/`, `Knowledge/Records/` — the five base type folders, created empty (a `.gitkeep` is not needed; Obsidian shows empty folders). There is no index file: every `Knowledge/` file carries a frontmatter `description`, and that is the inventory (contract: the wiki repo's `spec/knowledge-files.md`).
  - Area docs are **not** scaffolded — sessions duplicate the one global blank (path configured in global CLAUDE.md > Configuration > `templates.area`) to `area-<slug>.md` at the project root as domains emerge.
- Do **not** fabricate areas. A new project does not know its areas yet — the area map starts empty; areas are added when a domain has accumulated its own state.
- Set `knowledge_intake: true` in the CLAUDE.md frontmatter.

If **no:** Set `knowledge_intake: false` in frontmatter. The project can enable it later by setting `knowledge_intake: true` and scaffolding the orientation hierarchy (overview + type folders) per the template — or run the "Upgrade an existing project" checklist below.

## Step 5: Intent Engineering (Projects Only)

Ask the user:

> Does this project involve autonomous agent workflows or sustained multi-session development?

If **yes**, gather:

- **Objective** — What problem does this solve? (1-2 sentences, framed as a problem statement)
- **Desired Outcomes** — 2-4 observable state changes from the user's perspective
- **Health Metrics** — What must NOT degrade while pursuing outcomes?
- **Strategic Context** — What broader system or workflow does this project operate within? (Skip if standalone.)
- **Decision Authority** — What can agents do autonomously vs. what requires human confirmation?
- **Stop Rules** — When should agents halt or escalate?

Include these as active sections in the CLAUDE.md.

Reference for the user if they want background: path configured in global CLAUDE.md > Configuration > `references.three_disciplines`

If **no:** Leave the intent engineering sections as HTML comments in the CLAUDE.md (they exist in the template for future activation).

## Step 6: Create Structure

Based on the gathered answers, read the appropriate template and create:

**For Projects:**

```text
{parent}/{Project Name}/
  CLAUDE.md                    ← From project template, filled with gathered info + Linear project URL
  overview.md                  ← If Knowledge intake enabled — 30,000ft page + area map + house rules (project root)
  Knowledge/                   ← If Knowledge intake enabled (Step 4a)
  Knowledge/{Methods,Reference,Research,Decisions,Records}/  ← If Knowledge intake enabled — the five base type folders, empty
```

Do NOT create:

- `backlog.json` — task tracking is in Linear
- `backlog-archive.json` — this exists only for migrated projects (pre-cutoff)
- `progress.md` — session narrative is in Linear Project Updates
- `progress-archive.md` — this exists only for migrated projects (pre-cutoff)

**For Hubs:**

```text
{parent}/{Hub Name}/
  CLAUDE.md              ← From hub template, filled with gathered info
```

**CLAUDE.md requirements (per the canonical template):**

- Frontmatter: `status: active`, `description`, `updated`, `linear_project_id`, `linear_url`, `knowledge_intake` (no `tags`: the tag taxonomy was retired 2026-11-03; project discovery is by path)
- Template reference: the `template` frontmatter key, per the template's Frontmatter contract
- Re-entry Cue section (initialized as "No work in progress" or absent)
- Key Files table (only non-discoverable files)
- `build_home` frontmatter key (a list of absolute paths, one per repo) if applicable — see Publishing Safety Setup below, which also emits the paired repo working-guide CLAUDE.md
- Intent sections from Step 5 (if applicable)

## Step 7: Report

Summarize what was created:

- List all files and directories
- Confirm the Linear project was created and show the URL
- Note whether Knowledge intake is enabled (`knowledge_intake: true` in frontmatter). If so, confirm the orientation hierarchy scaffolded: `overview.md` at the project root (three-hop navigation contract + area guide) and the five `Knowledge/` type folders (`Methods/`, `Reference/`, `Research/`, `Decisions/`, `Records/`); no index file. Confirm the area map starts empty — no fabricated areas.
- Suggest: "Run `/session-start {Project Name}` when you're ready to begin working."

## Upgrade an existing project to the orientation hierarchy

`/new-project` builds the orientation hierarchy into every NEW project. Existing projects are **not** migrated automatically. This checklist ships the *capability* to upgrade one; it is run per-project, under operator direction, as its own slice with its own review — **do not** run it as a side effect of anything else.

Scope guards:

- **The System project stays grandfathered.** Its flat-root + `Knowledge/` layout is deliberate — do not apply this to it.
- Applying this to a real project (sorting its live Knowledge docs) is a judgment task per project, not a mechanical sweep. Run it when the operator asks, one project at a time.

Steps:

1. **Write `overview.md` at the project root** from the template skeleton — the durable "what this project is," how work moves, an empty (or illustrative) area map, and the house rules (three-hop navigation contract).
2. **Name the areas.** Identify the coherent slices that already have their own state — a session can work each without loading the others. Do not force a slice that isn't there yet.
3. **Sort current-state material into `area-<slug>.md` at the project root.** Current-state material folds into the area doc for its slice; frozen-reference and append-only records keep their own class (they are not areas) and stay in `Knowledge/`. Duplicate the global blank (`templates.area`) per area.
4. **Keep orientation files current-truth.** Area docs and the overview are rewritten in place, never annotated (their `description` ends "Current truth, mutated in place."); a `## State` section only where it is directional — where the area is headed, what is durably true (task status and logs stay in Linear). Append-only records stay append-only.
5. **Place each `Knowledge/` file in its type folder** (`Methods/`, `Reference/`, `Research/`, `Decisions/`, `Records/`; a project may add more) with the Obsidian CLI (`obsidian move`, which updates wikilinks), and make sure each carries `description`, `update`, `related` and `updated` in frontmatter. Root orientation files are mapped by the overview's area map; there is no index file.
6. **Verify:** three hops resolve (overview → each area → its artifacts), every `Knowledge/` file reachable from the folder it sits in (a `description` that says what it is; the describe tool lists the folder), every `Knowledge/` file in a type folder with the four frontmatter fields. Run the contract lint (the wiki plugin's `knowledge-description` skill) on the `Knowledge/` scope only — root orientation files are project scaffolding, checked against the template's § Orientation hierarchy, not the contract.

## Publishing Safety Setup (for projects with a GitHub repo)

When the project has its own git repo that pushes to GitHub, create it after the vault structure, through the `new-repo` skill (below). The repo lives outside the vault (operator rule: a git repo and an Obsidian folder are never the same directory) — under `~/Repos/{name}` for ordinary projects, `~/bin/{name}` for harness/system setup, or `~/Agents/{name}` for an agent's dev/deploy split.

**The CLAUDE.md pair:** add `build_home: ["{abs-path-to-repo}"]` to the vault project's frontmatter (a list — a project can have more than one repo). In the repo itself, the seeded CLAUDE.md carries `docs_home: "{abs-path-to-this-vault-project}"` pointing back. The repo file must be complete on its own — engines, CI runners, and cloud sessions see only the repo, never the vault.

**Creating the repo:** use the `new-repo` skill for its reviewed native setup procedure and Dotty assets. It prepares source changes and direct settings operations, verifies reviewer and merger App access and enrollment, and preserves existing repository extensions. Follow that procedure for creation, updates and conforming repeats. Use Dotty's `repo-claude-template.md` for the repository working guide and set its `docs_home` to the vault project.

Not all projects have GitHub repos. Hub-only or vault-only projects skip this section.

## Stop Rules

| Condition | Action |
| ----------- | -------- |
| User cancels at any step | Report what was gathered so far and stop. Do not create partial artifacts. |
| Linear project creation fails | Report the error and stop. Do not create vault structure until Linear project exists. |
| Parent location doesn't exist | Ask user to confirm creation or provide a different path. |
| Project name conflicts with existing folder | Warn and ask for a different name. Do not overwrite. |
| Template files not found | Report which templates are missing and stop. |
