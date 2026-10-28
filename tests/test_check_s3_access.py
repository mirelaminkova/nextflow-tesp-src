"""Unit tests for ansible/plugin-EESSI/files/check-s3-access.py, without network.

    python3 -m unittest discover -s tests -p 'test_*.py'

The signatures are AWS's published Signature Version 4 examples; the e2e job
(tests/e2e) runs the script against MinIO.
"""

import hashlib
import importlib.util
import pathlib
import unittest

SCRIPT = pathlib.Path(__file__).parent.parent / "ansible/plugin-EESSI/files/check-s3-access.py"
spec = importlib.util.spec_from_file_location("check_s3_access", SCRIPT)
check = importlib.util.module_from_spec(spec)
spec.loader.exec_module(check)


class SignatureTest(unittest.TestCase):
    def test_sigv4_test_suite_get_vanilla(self):
        # AWS SigV4 test suite, get-vanilla.
        auth = check.authorization(
            "GET", "https://example.amazonaws.com/",
            {"host": "example.amazonaws.com", "x-amz-date": "20150830T123600Z"},
            hashlib.sha256(b"").hexdigest(), "us-east-1", "service",
            "AKIDEXAMPLE", "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY", "20150830T123600Z")
        self.assertEqual(
            auth,
            "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, "
            "SignedHeaders=host;x-amz-date, "
            "Signature=5fa00fa31553b73ebf1942676e86291e8372ff2a2260956d9b8aae1d763fbf31")

    def test_s3_get_object_example(self):
        # S3 API reference, "Example: GET Object" (header-based authentication).
        empty = hashlib.sha256(b"").hexdigest()
        auth = check.authorization(
            "GET", "https://examplebucket.s3.amazonaws.com/test.txt",
            {"host": "examplebucket.s3.amazonaws.com", "range": "bytes=0-9",
             "x-amz-content-sha256": empty, "x-amz-date": "20130524T000000Z"},
            empty, "us-east-1", "s3",
            "AKIAIOSFODNN7EXAMPLE", "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY", "20130524T000000Z")
        self.assertTrue(auth.endswith(
            "Signature=f0e8bdb87c964420e857bd35b5d6ed310bd44f0170aba48dd91039c6036bdb41"))


class ObjectUrlTest(unittest.TestCase):
    def test_path_style(self):
        self.assertEqual(
            check.object_url("https://objectstore.surf.nl", "default", "path", "nf-bucket", "work/a b"),
            "https://objectstore.surf.nl/nf-bucket/work/a%20b")

    def test_endpoint_with_path_and_port(self):
        self.assertEqual(
            check.object_url("http://172.17.0.1:9000/s3/", "us-east-1", "path", "b", "w/k"),
            "http://172.17.0.1:9000/s3/b/w/k")

    def test_virtual_style(self):
        self.assertEqual(
            check.object_url("https://s3.example.org", "r", "virtual", "b", "w/k"),
            "https://b.s3.example.org/w/k")

    def test_aws_default_and_auto(self):
        self.assertEqual(
            check.object_url("", "eu-west-1", "auto", "b", "w/k"),
            "https://b.s3.eu-west-1.amazonaws.com/w/k")
        self.assertEqual(
            check.object_url("https://s3.example.org", "r", "auto", "b", "w/k"),
            "https://s3.example.org/b/w/k")


class ExplainTest(unittest.TestCase):
    def test_names_the_parameter_without_values(self):
        line = check.explain(403, "InvalidAccessKeyId", "https://objectstore.surf.nl", "s3://b/w")
        self.assertIn("src_s3_access_key_id", line)
        self.assertIn("CO secret", line)
        line = check.explain(403, "SignatureDoesNotMatch", "e", "s3://b/w")
        self.assertIn("src_s3_secret_access_key", line)

    def test_unknown_code(self):
        self.assertIn("HTTP 500", check.explain(500, None, "e", "s3://b/w"))


if __name__ == "__main__":
    unittest.main()
