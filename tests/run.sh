#!/usr/bin/env bash
# Runs every unit test playbook in tests/. Needs only ansible-core.
set -euo pipefail
cd "$(dirname "$0")/.."
for t in tests/*.yml; do
    echo "== $t"
    ansible-playbook -i localhost, -c local "$t"
done
