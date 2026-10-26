#!/usr/bin/env bash
# Checks the TES endpoint shape before Nextflow runs: nginx serves tesp-api under /tes/, and tesp-api's basic auth
# accepts the configured credentials and rejects a wrong password with 401.
# Usage: check-proxy-auth.sh ENDPOINT USERNAME PASSWORD
set -euo pipefail

endpoint=$1
user=$2
password=$3

status() {
    curl -sS -o /dev/null -w '%{http_code}' "$@"
}

code=$(status "$endpoint/v1/service-info")
echo "GET $endpoint/v1/service-info -> $code"
[ "$code" = 200 ] || { echo "service-info through nginx did not answer 200" >&2; exit 1; }

code=$(status -u "$user:$password" "$endpoint/v1/tasks")
echo "GET $endpoint/v1/tasks (right password) -> $code"
[ "$code" = 200 ] || { echo "the configured credentials were not accepted" >&2; exit 1; }

code=$(status -u "$user:not-the-password" "$endpoint/v1/tasks")
echo "GET $endpoint/v1/tasks (wrong password) -> $code"
[ "$code" = 401 ] || { echo "a wrong password was not rejected with 401; is basic auth enabled?" >&2; exit 1; }
