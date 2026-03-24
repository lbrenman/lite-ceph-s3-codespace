#!/usr/bin/env bash
# test-s3.sh — Basic smoke tests against the running Ceph S3 gateway

set -e

ENDPOINT="${S3_ENDPOINT:-http://localhost:7480}"
BUCKET="${BUCKET_NAME:-demo-bucket}"
TEST_KEY="smoke-test/hello.txt"
TEST_BODY="Hello from Ceph S3!"

AWS="aws --endpoint-url ${ENDPOINT} --no-verify-ssl"

echo "============================================"
echo " Ceph S3 Smoke Tests"
echo " Endpoint : ${ENDPOINT}"
echo " Bucket   : ${BUCKET}"
echo "============================================"
echo ""

# 1 — List buckets
echo "▶ [1/5] List all buckets..."
$AWS s3 ls
echo "  ✅ PASS"
echo ""

# 2 — Upload an object
echo "▶ [2/5] Upload object → s3://${BUCKET}/${TEST_KEY} ..."
echo "${TEST_BODY}" | $AWS s3 cp - "s3://${BUCKET}/${TEST_KEY}" --content-type "text/plain"
echo "  ✅ PASS"
echo ""

# 3 — List bucket contents
echo "▶ [3/5] List objects in bucket..."
$AWS s3 ls "s3://${BUCKET}/" --recursive
echo "  ✅ PASS"
echo ""

# 4 — Download and verify
echo "▶ [4/5] Download object and verify content..."
RESULT=$($AWS s3 cp "s3://${BUCKET}/${TEST_KEY}" - 2>/dev/null)
if echo "${RESULT}" | grep -q "Hello from Ceph S3"; then
  echo "  Content : '${RESULT}'"
  echo "  ✅ PASS"
else
  echo "  ❌ FAIL — unexpected content: '${RESULT}'"
  exit 1
fi
echo ""

# 5 — Delete the object
echo "▶ [5/5] Delete test object..."
$AWS s3 rm "s3://${BUCKET}/${TEST_KEY}"
echo "  ✅ PASS"
echo ""

echo "============================================"
echo " All smoke tests passed! ✅"
echo "============================================"
