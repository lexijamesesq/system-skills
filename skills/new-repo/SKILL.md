---
name: new-repo
description: >
  Triggers when the user asks to create a new GitHub repository (or "new repo",
  "set up a repo", "publish this as a repo", "enroll a repo in the estate").
  Creates it through the estate's one front door, dotty's new-repo.sh, and never
  hand-wires rulesets, CI or secrets.
---

# New repository

The estate has one front door for a new repository: `new-repo.sh` in dotty. It creates the repo, seeds the estate suite, declares it in dotty's rulesets, opens its callers PR, and sets its secrets. Don't hand-create rulesets, CI files or secrets, and don't run `provision-public-repo.sh` on a new repo. That script only converges a repo that's already enrolled.

## Before running

1. **The operator's authorization.** The script runs as the operator: her own `gh` login and her own `op`. That's a step outside the estate's App wrapper, so get her explicit go-ahead in this session, and never through a relay.
2. **The name and visibility.** Every estate repo sits under `lexijamesesq/`. Public is the default; pass `--private` for a private one.
3. **A dotty checkout at `main`, clean.** Clone it fresh into the session scratchpad:

   ```sh
   git clone https://github.com/lexijamesesq/dotty.git "$SCRATCH/dotty"
   ```

4. **The references file** `~/.config/estate/new-repo.env`. It holds the App-key references, and dotty-private's blueprint slice `new-repo-env` installs it. If it's missing, run `/system-blueprint apply` (or `new-repo-env.sh apply`); don't write it by hand.
5. **The operator's `gh`.** In a session, bare `gh` is the App wrapper, so make a one-line operator shim in the scratchpad:

   ```sh
   printf '#!/bin/sh\nunset GH_TOKEN GITHUB_TOKEN\nGH_CONFIG_DIR="$HOME/.config/gh" exec /opt/homebrew/bin/gh "$@"\n' >"$SCRATCH/gh-operator"
   chmod +x "$SCRATCH/gh-operator"
   ```

## Run

```sh
cd "$SCRATCH/dotty"
OPERATOR_GH="$SCRATCH/gh-operator" APP_GH="$HOME/.config/op-agent/bin/gh" OP=op \
  bash new-repo.sh [--private] --description "<one line>" lexijamesesq/<name>
```

Every step is idempotent, so re-running after a fix is safe. `op` asks for the operator's Touch ID for the two App keys.

## After the run

- **Two PRs:**
  - the declaration on dotty, which only the operator can admin-merge (rulesets are self-instrument);
  - the callers PR in the new repo.

  Rulesets apply once the declaration merges (`converge-on-merge.yml`).
- **The proof:** open a small PR in the new repo. It has to go green, get Margot's verdict and be merged by `ollie-the-intern[bot]`. That's also the proof that Margot's and Ollie's Apps reach the repo, which the script can't check itself.
- **A step that FAILs:** report its line as printed. If it's a bug in `new-repo.sh`, it goes to the dotty owner (system-lead), and nobody works around it by hand.
