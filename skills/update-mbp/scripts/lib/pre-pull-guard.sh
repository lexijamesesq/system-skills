#!/usr/bin/env bash
# _ump_pre_pull_guard — refuse the dotty pull while any profile still symlinks
# a skill into the dotty checkout.
#
# Why this exists: dotty no longer carries skills — every skill a profile
# serves comes from an installed plugin (work-lifecycle, wiki, operator). A
# profile link into ~/bin/dotty/.claude/skills is therefore always a leftover
# from before that profile was pruned, and a dotty pull that deletes the
# link's target would leave the profile with neither the link's target nor a
# plugin-served copy that outranks it — every command "succeeds" but the
# skill resolves nowhere. So the rule is one line with no name table: a link
# into that tree that still RESOLVES means the prune has not happened yet;
# refuse, name it, and say what to run. A dangling link resolves nothing and
# is swept by core.sh on its next apply, so it does not refuse.
#
# Shared source: embedded into the remote script apply-updates.sh generates,
# which runs the blueprint lane (plugins installed and enabled) BEFORE this
# guard and the dotty pull. Sourcing this file only defines the function;
# nothing executes on source. The caller gates only the dotty pull on it.
_ump_pre_pull_guard() {
  local profile profile_dir skills_dir entry name target found=0

  for profile in personal professional; do
    profile_dir="$HOME/.claude-$profile"
    [ -d "$profile_dir" ] || continue
    skills_dir="$profile_dir/skills"
    [ -d "$skills_dir" ] || continue

    for entry in "$skills_dir"/*; do
      [ -L "$entry" ] || continue
      name=$(basename "$entry")
      target=$(readlink "$entry")
      case "$target" in
        "$HOME/bin/dotty/.claude/skills"/*) ;;
        *) continue ;;
      esac
      # Dangling: nothing resolves through it; core.sh sweeps it on apply.
      [ -e "$entry" ] || continue
      echo "refusing to pull dotty: $profile still links $name into the checkout — prune the profile links with \`core.sh apply --prune\` (dotty-private blueprint), then re-run" >&2
      found=1
    done
  done

  [ "$found" = "0" ]
}
