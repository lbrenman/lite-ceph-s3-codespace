#!/usr/bin/env bash
set -e

echo "============================================"
echo " Lite Ceph S3 - Post-Create Setup"
echo "============================================"

# Install AWS CLI v2
echo "[1/3] Installing AWS CLI..."
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
sudo /tmp/aws/install
rm -rf /tmp/awscliv2.zip /tmp/aws

# Configure AWS CLI to point at local Ceph RGW
echo "[2/3] Configuring AWS CLI for Ceph..."
mkdir -p ~/.aws
cat > ~/.aws/credentials <<EOF
[default]
aws_access_key_id = ${ACCESS_KEY:-demo-key}
aws_secret_access_key = ${SECRET_KEY:-demo-secret}
EOF

cat > ~/.aws/config <<EOF
[default]
region = us-east-1
output = json
EOF

# Install jq (useful for parsing JSON responses)
echo "[3/3] Installing helper tools (curl, jq)..."
sudo apt-get update -qq
sudo apt-get install -y -qq curl jq

# Make all scripts executable
chmod +x scripts/*.sh examples/*.sh 2>/dev/null || true

echo ""
echo "============================================"
echo " Setup complete!"
echo " Run: bash scripts/start-ceph.sh"
echo "============================================"
