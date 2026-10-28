#!/usr/bin/env bash
# Runs every unit test in tests/: Python tests, then playbooks. Needs only
# ansible-core.
set -euo pipefail
cd "$(dirname "$0")/.."
echo "== tests/test_*.py"
python3 -m unittest discover -s tests -p 'test_*.py'
for t in tests/*.yml; do
    echo "== $t"
    ansible-playbook -i localhost, -c local "$t"
done
