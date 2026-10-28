#!/usr/bin/env bash
# Runs a command as the current user with a fresh set of groups, so it is in
# the stand-in CO group the e2e job adds after the runner started (a running
# process keeps the groups it started with). The runner's sudo resets the
# environment and refuses --preserve-env, so env sets it again, PATH too.
# Usage: as-co-member.sh COMMAND [ARGS...]
set -euo pipefail
mapfile -d '' vars < <(env -0)
exec sudo -u "$USER" -- env "${vars[@]}" "$@"
