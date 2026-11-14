---
name: new-project
description: >
  Set up a new project end to end: its project in Linear, its repository, its
  documentation in Notion, and the instruction file that ties them together.
  Triggers on "create a new project", "new project", "set up a project",
  "/new-project", or similar.
---

# New project

A project is four things, each with one home:

| Thing | Home | Made by |
| --- | --- | --- |
| The work | A project in Linear | This skill |
| The code | A repository | `/new-repo` |
| The documentation | A page and a Knowledge database in Notion | `/project-docs setup` |
| The instruction file | `CLAUDE.md` at the repository's root | `/new-repo` seeds it; this skill completes it |

The instruction file is the one a session reads first. It says what the project is and what it is for, and it points at the other three. This skill puts the four in place in order and carries each one's identifiers into that file.

Gather everything in step 1 before creating anything.

## 1. Gather

Ask the operator for:

- **Name.** Used for the Linear project, the repository and the Notion page.
- **Description.** One to three sentences: what the project is.
- **Intent.** The objective (the problem it solves), health metrics (what must not get worse), decision authority (what a session may do on its own and what needs her yes), and stop rules (when a session halts or asks).
- **The repository.** Its name, and whether it is public or private. Intent is published with the repository, so for a public one, agree which rules go in the instruction file and which belong on the project's Notion overview.
- **Where its Notion page goes.** She names the parent page.

A project with no code still needs a folder for its sessions to start in, because that is where the instruction file lives. Ask her where that is before going on.

## 2. The project in Linear

Call `linear_createProject` with the name, the description, and `teamIds` holding the team UUID from global CLAUDE.md > Configuration > `linear.team_lex_id`. Keep the returned project id and URL.

If this fails, stop. Nothing else is created until the Linear project exists.

## 3. The repository

Run `/new-repo` with the name, the description and the visibility. It creates the repository, installs the estate baseline, and seeds `CLAUDE.md` and `AGENTS.md`.

## 4. The documentation

Run `/project-docs setup` for the project, with the parent page she named and the repository as the folder sessions start in. It creates the project's page and Knowledge database in Notion and returns their two pointers. A new project starts with no areas.

## 5. The instruction file

Complete the repository's `CLAUDE.md` from what you now hold:

- Front matter: `linear_project_id` and `linear_url` from step 2; `notion_project` and `notion_knowledge` from step 4.
- The **Intent** section from step 1.

This is a change to the repository, so it goes through that repository's review like any other.

## 6. Report

Tell the operator what exists now, with links: the Linear project, the repository, the Notion page. Say what is still open, such as a pull request waiting on her. The next session started in the repository will be pointed at all of it.

## Stop when

| Condition | Do |
| --- | --- |
| The operator cancels | Say what was gathered and what, if anything, was already created. Create nothing further |
| The Linear project cannot be created | Report the error and stop |
| A repository or Notion page of that name already exists | Ask before going on. Never overwrite |
| `/new-repo` or `/project-docs setup` stops partway | Report where it stopped. Do not complete the instruction file with missing values |
