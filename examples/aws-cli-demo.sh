#!/usr/bin/env bash
# aws-cli-demo.sh — AWS CLI walkthrough against Ceph S3

ENDPOINT="${S3_ENDPOINT:-http://localhost:7480}"
BUCKET="${BUCKET_NAME:-demo-bucket}"
AWS="aws --endpoint-url ${ENDPOINT} --no-verify-ssl"

echo "============================================"
echo " AWS CLI → Ceph S3 Demo"
echo " Endpoint : ${ENDPOINT}"
echo "============================================"
echo ""

# ── Buckets ────────────────────────────────────
echo "── Buckets ──────────────────────────────────"

echo "List buckets:"
$AWS s3 ls
echo ""

echo "Create a new bucket:"
$AWS s3 mb s3://my-new-bucket
$AWS s3 ls
echo ""

# ── Objects ────────────────────────────────────
echo "── Objects ──────────────────────────────────"

echo "Upload a text file:"
echo "Hello Ceph!" > /tmp/hello.txt
$AWS s3 cp /tmp/hello.txt s3://${BUCKET}/hello.txt
echo ""

echo "Upload a JSON file:"
echo '{"service":"ceph","status":"ok"}' > /tmp/data.json
$AWS s3 cp /tmp/data.json s3://${BUCKET}/data/status.json --content-type application/json
echo ""

echo "List objects in bucket:"
$AWS s3 ls s3://${BUCKET}/ --recursive
echo ""

echo "Download an object:"
$AWS s3 cp s3://${BUCKET}/hello.txt /tmp/hello-downloaded.txt
echo "Downloaded content: $(cat /tmp/hello-downloaded.txt)"
echo ""

echo "Copy object to a new key:"
$AWS s3 cp s3://${BUCKET}/hello.txt s3://${BUCKET}/backup/hello.txt
echo ""

echo "Sync a local directory to a bucket prefix:"
mkdir -p /tmp/sync-demo
echo "file1" > /tmp/sync-demo/file1.txt
echo "file2" > /tmp/sync-demo/file2.txt
$AWS s3 sync /tmp/sync-demo/ s3://${BUCKET}/sync-demo/
echo ""

echo "List objects after sync:"
$AWS s3 ls s3://${BUCKET}/ --recursive
echo ""

# ── Object metadata ────────────────────────────
echo "── Object Metadata ──────────────────────────"

echo "Head object (metadata only):"
$AWS s3api head-object \
  --bucket ${BUCKET} \
  --key hello.txt
echo ""

echo "Upload with custom metadata:"
$AWS s3 cp /tmp/hello.txt s3://${BUCKET}/tagged.txt \
  --metadata "author=demo,env=codespace"
echo ""

# ── Cleanup ────────────────────────────────────
echo "── Cleanup ──────────────────────────────────"

echo "Delete a single object:"
$AWS s3 rm s3://${BUCKET}/backup/hello.txt
echo ""

echo "Delete all objects under a prefix:"
$AWS s3 rm s3://${BUCKET}/sync-demo/ --recursive
echo ""

echo "Remove the bucket we created:"
$AWS s3 rb s3://my-new-bucket
echo ""

echo "============================================"
echo " AWS CLI demo complete ✅"
echo "============================================"
