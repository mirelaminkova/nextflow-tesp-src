#!/usr/bin/env bash
# Runs a command as the current user with a fresh set of groups, so it is in
# the stand-in CO group the e2e job adds after the runner started (a running
# process keeps the groups it started with). Keeps the environment, PATH too.
# Usage: as-co-member.sh COMMAND [ARGS...]
set -euo pipefail
exec sudo --preserve-env -u "$USER" -- env "PATH=$PATH" "$@"
