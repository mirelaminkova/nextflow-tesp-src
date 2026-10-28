#!/usr/bin/env bash
# Runs every unit test in tests/: Python tests, then playbooks. Needs only
# ansible-core.
set -euo pipefail
cd "$(dirname "$0")/.."
echo "== tests/test_*.py"
# No __pycache__: it would land next to the script in files/, which
# tests/plugin-eessi.yml requires to hold only files the playbook uses.
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p 'test_*.py'
for t in tests/*.yml; do
    echo "== $t"
    ansible-playbook -i localhost, -c local "$t"
done
