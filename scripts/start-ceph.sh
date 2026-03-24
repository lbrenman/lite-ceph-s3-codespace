#!/usr/bin/env bash
# start-ceph.sh — Pull and run the lite-ceph-s3-gw demo container

set -e

# ── Configuration ──────────────────────────────────────────────────
CONTAINER_NAME="lite-ceph-s3"
CEPH_IMAGE="emadalblueshi/lite-ceph-s3-gw:v1.0.0"
BUCKET="${BUCKET_NAME:-demo-bucket}"
ACCESS="${ACCESS_KEY:-demo-key}"
SECRET="${SECRET_KEY:-demo-secret}"
# ───────────────────────────────────────────────────────────────────

echo "============================================"
echo " Starting Lite Ceph S3 Gateway Container"
echo "============================================"

# Stop and remove any previous run
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Removing existing container '${CONTAINER_NAME}'..."
  docker rm -f "${CONTAINER_NAME}"
fi

echo "Pulling image: ${CEPH_IMAGE} ..."
docker pull "${CEPH_IMAGE}"

echo ""
echo "Starting Ceph with:"
echo "  S3 endpoint (HTTP)  : http://localhost:7480"
echo "  S3 endpoint (HTTPS) : https://localhost:7443"
echo "  Access Key          : ${ACCESS}"
echo "  Secret Key          : ${SECRET}"
echo "  Default Bucket      : ${BUCKET}"
echo ""

docker run -d \
  --name "${CONTAINER_NAME}" \
  -p 7480:7480 \
  -p 7443:7443 \
  -e BUCKET_NAME="${BUCKET}" \
  -e ACCESS_KEY="${ACCESS}" \
  -e SECRET_KEY="${SECRET}" \
  "${CEPH_IMAGE}"

echo "Waiting for Ceph RGW to become ready..."

RETRIES=20
for i in $(seq 1 $RETRIES); do
  if curl -sf http://localhost:7480/ > /dev/null 2>&1; then
    echo ""
    echo "✅ Ceph S3 gateway is ready!"

    # ── Disable virtual-hosted-style bucket routing ──────────────────
    # By default Ceph RGW parses the Host header and treats the first
    # segment as a bucket name (virtual-hosted style). When accessed via
    # a forwarded URL (ngrok, Codespaces, iPaaS), the hostname gets
    # mistaken for a bucket name and every request returns NoSuchBucket.
    # Setting rgw_dns_name to "" tells RGW not to do this, forcing
    # path-style routing: host/bucket/key instead of bucket.host/key.
    echo ""
    echo "Configuring RGW for path-style routing (disabling virtual-hosted-style)..."
    docker exec "${CONTAINER_NAME}" ceph config set client.rgw rgw_dns_name ""
    echo "  ✅ rgw_dns_name set to empty string"

    # Restart RGW inside the container to pick up the config change
    echo "Restarting RGW to apply config..."
    docker exec "${CONTAINER_NAME}" pkill -f radosgw || true
    sleep 5

    # Wait for RGW to come back
    for j in $(seq 1 10); do
      if curl -sf http://localhost:7480/ > /dev/null 2>&1; then
        echo "  ✅ RGW restarted successfully"
        break
      fi
      printf "  Waiting for RGW restart... %d/10\n" "$j"
      sleep 3
    done
    # ────────────────────────────────────────────────────────────────

    echo ""
    echo "Next steps:"
    echo "  bash scripts/test-s3.sh         # Run basic S3 smoke tests"
    echo "  bash examples/aws-cli-demo.sh   # AWS CLI walkthrough"
    echo "  bash examples/curl-demo.sh      # Raw REST API examples"
    exit 0
  fi
  printf "  Attempt %d/%d — not ready yet, waiting 5s...\n" "$i" "$RETRIES"
  sleep 5
done

echo ""
echo "⚠️  Ceph did not become ready in time. Check container logs:"
echo "  docker logs ${CONTAINER_NAME}"
exit 1
