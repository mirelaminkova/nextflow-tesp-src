#!/usr/bin/env bash
# Failure diagnostics for the e2e job: compose state and logs, nginx logs, Nextflow logs and the TES tasks as
# tesp-api sees them. The job log is public: everything goes through redact(), which masks presigned-URL
# parameters (signatures, credentials). The remaining credentials are throwaway CI test values.
# Usage: dump-debug.sh TESP_API_DIR NEXTFLOW_LOG_DIR TES_USER TES_PASSWORD
set -u

tesp_dir=$1
log_dir=$2
user=$3
password=$4

redact() {
    sed -E 's/(X-Amz-(Signature|Credential|Security-Token)|AWSAccessKeyId|Signature)=[^&" ]*/\1=REDACTED/gI'
}

section() {
    printf '\n===== %s =====\n' "$1"
}

section "docker compose ps"
(cd "$tesp_dir" && docker compose --profile pulsar ps -a)

for service in tesp-api pulsar_rest minio; do
    section "docker compose logs $service"
    (cd "$tesp_dir" && docker compose --profile pulsar logs --no-color --tail 400 "$service" 2>&1) | redact
done

section "nginx logs"
docker logs tes-nginx 2>&1 | tail -n 200 | redact

section "TES tasks (view=FULL)"
curl -sS -u "$user:$password" 'http://localhost:8080/v1/tasks?view=FULL' | redact
echo

for f in "$log_dir"/*.log; do
    [ -f "$f" ] || continue
    section "$f"
    redact < "$f"
done
