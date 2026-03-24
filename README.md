# Ceph S3 Gateway — GitHub Codespace Demo

A ready-to-run GitHub Codespace for testing the [Ceph](https://ceph.com) S3-compatible object storage API using the lightweight [`emadalblueshi/lite-ceph-s3-gw`](https://hub.docker.com/r/emadalblueshi/lite-ceph-s3-gw) Docker image.

This repo spins up a real Ceph RADOS Gateway (RGW) inside your Codespace so you can make S3 REST API calls without any AWS account or external services.

---

## What's Inside

```
.
├── .devcontainer/
│   ├── devcontainer.json     # Codespace configuration
│   └── post-create.sh        # Installs AWS CLI, configures credentials
├── scripts/
│   ├── start-ceph.sh         # Pull and start the Ceph container
│   └── test-s3.sh            # Basic smoke tests (upload/download/delete)
├── examples/
│   ├── aws-cli-demo.sh       # Full AWS CLI walkthrough
│   └── curl-demo.sh          # Raw S3 REST API calls with Signature V4
├── .gitignore
└── README.md
```

---

## Quick Start

### Option A — Open in GitHub Codespaces (recommended)

1. Click **Code → Codespaces → Create codespace on main** in this repo.
2. Wait for the Codespace to build (~2 minutes). The `post-create.sh` script will automatically install the AWS CLI and configure it.
3. In the terminal, start Ceph:

```bash
bash scripts/start-ceph.sh
```

4. Wait ~30 seconds for the Ceph RGW to become ready. You will see:

```
✅ Ceph S3 gateway is ready!
```

5. Run the smoke tests:

```bash
bash scripts/test-s3.sh
```

### Option B — Clone and run locally

Requirements: Docker, bash, curl, openssl

```bash
git clone https://github.com/YOUR_USERNAME/lite-ceph-s3-gw-codespace.git
cd lite-ceph-s3-gw-codespace

# Install AWS CLI if needed, then:
export BUCKET_NAME=demo-bucket
export ACCESS_KEY=demo-key
export SECRET_KEY=demo-secret
export S3_ENDPOINT=http://localhost:7480

bash scripts/start-ceph.sh
bash scripts/test-s3.sh
```

---

## Endpoints

| Port | Protocol | Purpose |
|------|----------|---------|
| `7480` | HTTP  | S3 REST API (use for all examples) |
| `7443` | HTTPS | S3 REST API (TLS, self-signed cert) |

GitHub Codespaces will automatically detect these ports and offer to forward them. You can use the forwarded HTTPS URL to test from Postman or any external REST client.

---

## Default Credentials

These are set as environment variables in `devcontainer.json` and configured automatically in `~/.aws/credentials` by `post-create.sh`.

| Variable | Default Value |
|----------|--------------|
| `ACCESS_KEY` | `demo-key` |
| `SECRET_KEY` | `demo-secret` |
| `BUCKET_NAME` | `demo-bucket` |
| `S3_ENDPOINT` | `http://localhost:7480` |

> **Note:** These are local demo credentials only. Do not use real AWS credentials with this container.

---

## Examples

### Using the AWS CLI

The AWS CLI is pre-installed and pre-configured. All commands use `--endpoint-url` to redirect to Ceph instead of AWS.

```bash
# List buckets
aws s3 ls --endpoint-url http://localhost:7480

# Create a bucket
aws s3 mb s3://my-bucket --endpoint-url http://localhost:7480

# Upload a file
aws s3 cp myfile.txt s3://demo-bucket/myfile.txt --endpoint-url http://localhost:7480

# Download a file
aws s3 cp s3://demo-bucket/myfile.txt ./downloaded.txt --endpoint-url http://localhost:7480

# List objects in a bucket
aws s3 ls s3://demo-bucket/ --endpoint-url http://localhost:7480

# Delete an object
aws s3 rm s3://demo-bucket/myfile.txt --endpoint-url http://localhost:7480
```

Run the full AWS CLI walkthrough:

```bash
bash examples/aws-cli-demo.sh
```

### Using the S3 API (`s3api`)

```bash
# Head object (get metadata without downloading)
aws s3api head-object \
  --bucket demo-bucket \
  --key myfile.txt \
  --endpoint-url http://localhost:7480

# Put object with custom metadata
aws s3api put-object \
  --bucket demo-bucket \
  --key tagged.txt \
  --body myfile.txt \
  --metadata "author=demo,env=codespace" \
  --endpoint-url http://localhost:7480

# Get object ACL
aws s3api get-object-acl \
  --bucket demo-bucket \
  --key myfile.txt \
  --endpoint-url http://localhost:7480
```

### Using raw curl (Signature V4)

For testing the raw HTTP REST API without the AWS CLI:

```bash
# Simple unauthenticated GET (lists bucket — works if bucket is public)
curl http://localhost:7480/demo-bucket/

# Run the full signed curl demo
bash examples/curl-demo.sh
```

The `curl-demo.sh` script shows how to construct AWS Signature V4 manually using `openssl` and `curl` — useful for understanding what the SDK does under the hood, or for testing from an environment where you only have curl available (e.g., inside an Amplify Fusion flow).

---

## Stopping and Restarting

```bash
# Stop the container
docker stop lite-ceph-s3

# Start it again (no need to re-pull)
docker start lite-ceph-s3

# Remove and recreate from scratch
docker rm -f lite-ceph-s3
bash scripts/start-ceph.sh
```

---

## View Container Logs

```bash
docker logs lite-ceph-s3
docker logs -f lite-ceph-s3   # follow (tail -f style)
```

---

## About the Image

[`emadalblueshi/lite-ceph-s3-gw`](https://hub.docker.com/r/emadalblueshi/lite-ceph-s3-gw) is a community-maintained lightweight Ceph demo container. It uses Ceph's `memstore` backend (in-memory — data is lost when the container stops) and runs only the components needed for the RADOS Gateway (RGW), making it significantly faster to start than the official `ceph/daemon demo` image.

| | lite-ceph-s3-gw | ceph/daemon demo |
|-|-----------------|-----------------|
| Start time | ~20–30s | ~60–90s |
| Privileged mode required | No | Yes |
| Data persistence | In-memory only | Can mount volumes |
| Image size | Smaller | Larger |
| Best for | Integration tests, API demos | Closer-to-production simulation |

---

## S3 API Compatibility

Ceph RGW supports the core S3 REST API. Commonly used operations that work with this image:

- `GET /` — list buckets
- `PUT /<bucket>` — create bucket
- `DELETE /<bucket>` — delete bucket
- `GET /<bucket>` — list objects
- `PUT /<bucket>/<key>` — upload object
- `GET /<bucket>/<key>` — download object
- `HEAD /<bucket>/<key>` — object metadata
- `DELETE /<bucket>/<key>` — delete object
- `POST /<bucket>/<key>?uploads` — initiate multipart upload

---

## License

MIT
