#!/usr/bin/env bash
# Negative check (issue #3): with a wrong TES password `nextflow run` must fail, and fail because of the
# credentials (401 / Unauthorized), which proves basic auth is actually in the request path.
# Run from tests/e2e. Usage: run-negative.sh OUT_DIR
set -uo pipefail

out_dir=$1
mkdir -p "$out_dir"
console="$out_dir/negative.console.log"
nf_log="$out_dir/negative.nextflow.log"

if nextflow -log "$nf_log" run main.nf \
        -c wrong-password.config \
        -work-dir s3://tesp-test/work-negative \
        --outdir "$out_dir/results" > "$console" 2>&1; then
    cat "$console"
    echo "nextflow run succeeded with a wrong TES password; basic auth is not enforced" >&2
    exit 1
fi
cat "$console"

if grep -iEq '401|unauthori' "$console" "$nf_log"; then
    echo "nextflow run failed as expected, rejected by TES basic auth:"
    grep -ihE '401|unauthori' "$console" "$nf_log" | head -n 5
    exit 0
fi
echo "nextflow run failed, but not with 401/Unauthorized; see $nf_log" >&2
exit 1
