#!/usr/bin/env bash
# curl-demo.sh — Raw S3 REST API calls against Ceph using AWS Signature V4
#
# Dependencies: curl, openssl, xxd (all pre-installed in the devcontainer)

set -e

ENDPOINT="${S3_ENDPOINT:-http://localhost:7480}"
BUCKET="${BUCKET_NAME:-demo-bucket}"
ACCESS="${ACCESS_KEY:-demo-key}"
SECRET="${SECRET_KEY:-demo-secret}"
REGION="us-east-1"
SERVICE="s3"

# ── Signature V4 helper ────────────────────────────────────────────────────
# Usage: signed_curl <METHOD> <PATH> [BODY] [CONTENT_TYPE]
signed_curl() {
  local METHOD="$1"
  local S3_PATH="$2"
  local BODY="${3:-}"
  local CONTENT_TYPE="${4:-application/octet-stream}"

  local HOST
  HOST=$(echo "$ENDPOINT" | sed 's|http[s]*://||')
  local DATETIME
  DATETIME=$(date -u +"%Y%m%dT%H%M%SZ")
  local DATE="${DATETIME:0:8}"

  local PAYLOAD_HASH
  if [ -n "$BODY" ]; then
    PAYLOAD_HASH=$(echo -n "$BODY" | openssl dgst -sha256 | awk '{print $2}')
  else
    PAYLOAD_HASH="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  fi

  local CANONICAL_HEADERS="content-type:${CONTENT_TYPE}\nhost:${HOST}\nx-amz-content-sha256:${PAYLOAD_HASH}\nx-amz-date:${DATETIME}\n"
  local SIGNED_HEADERS="content-type;host;x-amz-content-sha256;x-amz-date"

  local CANONICAL_REQUEST="${METHOD}\n${S3_PATH}\n\n${CANONICAL_HEADERS}\n${SIGNED_HEADERS}\n${PAYLOAD_HASH}"
  local CR_HASH
  CR_HASH=$(echo -e "$CANONICAL_REQUEST" | openssl dgst -sha256 | awk '{print $2}')

  local STRING_TO_SIGN="AWS4-HMAC-SHA256\n${DATETIME}\n${DATE}/${REGION}/${SERVICE}/aws4_request\n${CR_HASH}"

  hmac_sha256() { echo -n "$2" | openssl dgst -sha256 -mac HMAC -macopt "$1" | awk '{print $2}'; }
  local DATE_KEY;    DATE_KEY=$(hmac_sha256    "key:AWS4${SECRET}"   "$DATE")
  local REGION_KEY;  REGION_KEY=$(hmac_sha256  "hexkey:${DATE_KEY}"  "$REGION")
  local SERVICE_KEY; SERVICE_KEY=$(hmac_sha256 "hexkey:${REGION_KEY}" "$SERVICE")
  local SIGNING_KEY; SIGNING_KEY=$(hmac_sha256 "hexkey:${SERVICE_KEY}" "aws4_request")

  local SIGNATURE
  SIGNATURE=$(echo -e "$STRING_TO_SIGN" | openssl dgst -sha256 -mac HMAC -macopt "hexkey:${SIGNING_KEY}" | awk '{print $2}')

  local AUTH="AWS4-HMAC-SHA256 Credential=${ACCESS}/${DATE}/${REGION}/${SERVICE}/aws4_request, SignedHeaders=${SIGNED_HEADERS}, Signature=${SIGNATURE}"

  if [ -n "$BODY" ]; then
    curl -s -X "$METHOD" "${ENDPOINT}${S3_PATH}" \
      -H "Host: ${HOST}" \
      -H "Content-Type: ${CONTENT_TYPE}" \
      -H "x-amz-date: ${DATETIME}" \
      -H "x-amz-content-sha256: ${PAYLOAD_HASH}" \
      -H "Authorization: ${AUTH}" \
      -d "$BODY"
  else
    curl -s -X "$METHOD" "${ENDPOINT}${S3_PATH}" \
      -H "Host: ${HOST}" \
      -H "Content-Type: ${CONTENT_TYPE}" \
      -H "x-amz-date: ${DATETIME}" \
      -H "x-amz-content-sha256: ${PAYLOAD_HASH}" \
      -H "Authorization: ${AUTH}"
  fi
}
# ──────────────────────────────────────────────────────────────────────────

echo "============================================"
echo " Raw curl → Ceph S3 REST API Demo"
echo " Endpoint : ${ENDPOINT}"
echo "============================================"
echo ""

echo "── [1] List Buckets (GET /) ──────────────────"
signed_curl GET "/" "" "application/xml"
echo -e "\n"

echo "── [2] List Objects in Bucket (GET /<bucket>) ─"
signed_curl GET "/${BUCKET}" "" "application/xml"
echo -e "\n"

echo "── [3] PUT Object ────────────────────────────"
signed_curl PUT "/${BUCKET}/curl-test.txt" "Hello from raw curl!" "text/plain"
echo -e "\n"

echo "── [4] GET Object ────────────────────────────"
signed_curl GET "/${BUCKET}/curl-test.txt" "" "text/plain"
echo -e "\n"

echo "── [5] HEAD Object (metadata) ────────────────"
HOST=$(echo "$ENDPOINT" | sed 's|http[s]*://||')
DATETIME=$(date -u +"%Y%m%dT%H%M%SZ")
# HEAD via signed curl (simpler — no body hash needed)
curl -s -I "${ENDPOINT}/${BUCKET}/curl-test.txt" \
  -H "Host: ${HOST}" \
  -H "x-amz-date: ${DATETIME}"
echo ""

echo "── [6] DELETE Object ─────────────────────────"
signed_curl DELETE "/${BUCKET}/curl-test.txt" "" "application/octet-stream"
echo -e "\n"

echo "── [7] Verify Deletion (list bucket) ─────────"
signed_curl GET "/${BUCKET}" "" "application/xml"
echo -e "\n"

echo "============================================"
echo " curl REST demo complete ✅"
echo "============================================"
