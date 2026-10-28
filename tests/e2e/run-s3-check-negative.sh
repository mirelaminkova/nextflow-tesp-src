#!/usr/bin/env bash
# Negative check of the deploy-time S3 check: with an unknown access key or a wrong secret key, rendering the
# config must fail, and fail with the hint for that parameter, without printing the key.
# Run from the repository root with the e2e job's environment. Usage: run-s3-check-negative.sh
set -uo pipefail

expect_failure() {
    local why=$1 expect=$2 out
    shift 2
    if out=$(ansible-playbook -i localhost, -c local tests/e2e/render-config.yml \
            -e out=/dev/null "$@" 2>&1); then
        echo "$out"
        echo "the S3 check accepted $why" >&2
        return 1
    fi
    if ! grep -q -- "$expect" <<< "$out"; then
        echo "$out"
        echo "the S3 check failed for $why, but without '$expect'" >&2
        return 1
    fi
    if grep -qF -- "${S3_SECRET_ACCESS_KEY:?}" <<< "$out"; then
        echo "the S3 check printed the secret key" >&2
        return 1
    fi
    echo "rejected as expected ($why):"
    grep -o "Can't write to src_nf_workdir.*" <<< "$out" | head -n 1
}

expect_failure "an unknown access key" InvalidAccessKeyId -e src_s3_access_key_id=no-such-key &&
    expect_failure "a wrong secret key" SignatureDoesNotMatch -e src_s3_secret_access_key=wrong-secret
