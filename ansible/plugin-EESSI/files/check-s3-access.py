#!/usr/bin/env python3
"""Checks that the S3 key pair can write to the Nextflow work directory.

Writes a small object under the src_nf_workdir prefix and deletes it again,
signed with AWS Signature Version 4, using only the standard library (the
workspace has no boto3). Settings come from the environment, never from
arguments, which other accounts can read in the process list:

    NF_WORKDIR                s3://<bucket>/<prefix>
    NF_S3_ENDPOINT_URL        empty for AWS S3
    NF_S3_REGION
    NF_S3_ACCESS_KEY_ID
    NF_S3_SECRET_ACCESS_KEY
    NF_S3_ADDRESSING_STYLE    path, virtual or auto

On failure it prints one line naming the cause and exits 1, or 2 when the
endpoint could not be reached (worth a retry). It prints the S3 error code
only, never the error message or the keys: the playbook shows this output.
"""

import datetime
import hashlib
import hmac
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid
import xml.etree.ElementTree as ET

EMPTY_SHA256 = hashlib.sha256(b"").hexdigest()


def _hmac(key, msg):
    return hmac.new(key, msg.encode(), hashlib.sha256).digest()


def authorization(method, url, headers, payload_sha256, region, service,
                  access_key_id, secret_access_key, amz_date):
    """Authorization header value for a request (SigV4, header signing).

    headers: every header to sign, names in lower case, host included.
    url: path and query already URI-encoded as they go on the wire.
    """
    parts = urllib.parse.urlsplit(url)
    query = sorted(urllib.parse.parse_qsl(parts.query, keep_blank_values=True))
    canonical_query = "&".join(
        urllib.parse.quote(k, safe="-_.~") + "=" + urllib.parse.quote(v, safe="-_.~")
        for k, v in query)
    names = sorted(headers)
    canonical_headers = "".join(f"{n}:{' '.join(headers[n].split())}\n" for n in names)
    signed_headers = ";".join(names)
    canonical_request = "\n".join([
        method, parts.path or "/", canonical_query, canonical_headers,
        signed_headers, payload_sha256])
    scope = f"{amz_date[:8]}/{region}/{service}/aws4_request"
    string_to_sign = "\n".join([
        "AWS4-HMAC-SHA256", amz_date, scope,
        hashlib.sha256(canonical_request.encode()).hexdigest()])
    key = ("AWS4" + secret_access_key).encode()
    for part in (amz_date[:8], region, service, "aws4_request"):
        key = _hmac(key, part)
    signature = hmac.new(key, string_to_sign.encode(), hashlib.sha256).hexdigest()
    return (f"AWS4-HMAC-SHA256 Credential={access_key_id}/{scope}, "
            f"SignedHeaders={signed_headers}, Signature={signature}")


def object_url(endpoint_url, region, style, bucket, key):
    """URL of an object, with the path URI-encoded once, as S3 signs it."""
    if not endpoint_url:
        endpoint_url = f"https://s3.{region}.amazonaws.com"
    if style == "auto":
        # What the AWS SDK picks: path style for a custom endpoint.
        style = "virtual" if "amazonaws.com" in endpoint_url else "path"
    parts = urllib.parse.urlsplit(endpoint_url)
    path = parts.path.rstrip("/")
    netloc = parts.netloc
    if style == "virtual":
        netloc = f"{bucket}.{netloc}"
    else:
        path += "/" + urllib.parse.quote(bucket, safe="-_.~")
    path += "/" + urllib.parse.quote(key, safe="-_.~/")
    return urllib.parse.urlunsplit((parts.scheme, netloc, path, "", ""))


def s3_request(method, url, body, region, access_key_id, secret_access_key):
    """Sends a signed request. Returns (HTTP status, S3 error code or None)."""
    amz_date = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    payload_sha256 = hashlib.sha256(body).hexdigest() if body else EMPTY_SHA256
    headers = {
        "host": urllib.parse.urlsplit(url).netloc,
        "x-amz-content-sha256": payload_sha256,
        "x-amz-date": amz_date,
    }
    headers["authorization"] = authorization(
        method, url, headers, payload_sha256, region, "s3",
        access_key_id, secret_access_key, amz_date)
    request = urllib.request.Request(url, data=body or None, method=method, headers=headers)
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return response.status, None
    except urllib.error.HTTPError as err:
        code = None
        try:
            code = ET.fromstring(err.read()).findtext("Code")
        except ET.ParseError:
            pass
        return err.code, code


def explain(status, code, endpoint, workdir):
    """One line for the deployment log on why the write failed."""
    hints = {
        "InvalidAccessKeyId": (
            f"src_s3_access_key_id is not a key that {endpoint} knows. Check the CO "
            "secret it comes from: the key may be revoked, mistyped, or from another "
            "object store project."),
        "SignatureDoesNotMatch": (
            "src_s3_secret_access_key does not belong to src_s3_access_key_id. Check "
            "the CO secret it comes from."),
        "AccessDenied": (
            f"the S3 key pair is valid but may not write to {workdir}. Use a key "
            "pair that can write to this bucket, or another src_nf_workdir."),
        "NoSuchBucket": (
            f"the bucket of src_nf_workdir ({workdir}) does not exist at {endpoint}."),
        "AuthorizationHeaderMalformed": (
            "the S3 endpoint rejected src_s3_region. Set the region the bucket is in."),
        "PermanentRedirect": (
            "the bucket is in another region, or needs src_s3_addressing_style "
            "virtual. Check src_s3_region and src_s3_addressing_style."),
    }
    hint = hints.get(code, f"S3 answered HTTP {status}.")
    return f"Can't write to src_nf_workdir {workdir} at {endpoint} ({code or status}): {hint}"


def main():
    env = os.environ
    workdir = env["NF_WORKDIR"].rstrip("/")
    endpoint_url = env.get("NF_S3_ENDPOINT_URL", "")
    region = env.get("NF_S3_REGION") or "us-east-1"
    access_key_id = env["NF_S3_ACCESS_KEY_ID"]
    secret_access_key = env["NF_S3_SECRET_ACCESS_KEY"]
    style = env.get("NF_S3_ADDRESSING_STYLE") or "path"

    bucket, _, prefix = workdir[len("s3://"):].partition("/")
    key = f"{prefix}/.nextflow-tesp-src-check-{uuid.uuid4().hex}"
    url = object_url(endpoint_url, region, style, bucket, key)
    endpoint = endpoint_url or "AWS S3"

    try:
        status, code = s3_request(
            "PUT", url, b"nextflow-tesp-src deployment check\n",
            region, access_key_id, secret_access_key)
        if status >= 300:
            print(explain(status, code, endpoint, workdir))
            return 1
        # Nextflow needs write access only; a probe left behind is harmless.
        s3_request("DELETE", url, b"", region, access_key_id, secret_access_key)
    except (urllib.error.URLError, OSError) as err:
        reason = getattr(err, "reason", err)
        print(f"Can't reach the S3 endpoint {endpoint}: {reason}")
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
