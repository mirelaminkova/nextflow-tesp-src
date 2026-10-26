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
        -work-dir "${NF_WORKDIR:?}-negative" \
        --outdir "$out_dir/results" > "$console" 2>&1; then
    cat "$console"
    echo "nextflow run succeeded with a wrong TES password; basic auth is not enforced" >&2
    exit 1
fi
cat "$console"

# Only the console's error report counts: the Nextflow log also holds URL-encoded plugin pins such as
# nf-ga4gh%401.5.0, so a bare "401" would match there whatever the failure was.
auth_error='(^|[^%[:alnum:]])401([^.[:alnum:]]|$)|unauthori[sz]ed'
if grep -iEq "$auth_error" "$console"; then
    echo "nextflow run failed as expected, rejected by TES basic auth:"
    grep -iE "$auth_error" "$console" | head -n 5
    exit 0
fi
echo "nextflow run failed, but not with 401/Unauthorized:" >&2
tail -n 50 "$nf_log" >&2
exit 1
