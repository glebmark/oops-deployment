#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../client"

# 1. Cross-compile
echo "==> Cross-compiling for linux/amd64..."
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-s -w" -o cluster-agent-linux .

# 2. Build & push
# Can't use the repo Dockerfile directly — docker build --platform linux/amd64 runs
# the Go compiler under QEMU emulation on Apple Silicon, which crashes the Go GC.
# Instead: compile natively above, then package the pre-built binary with an inline
# Dockerfile that is just the second stage of the repo Dockerfile.
echo "==> Building image..."
docker build --platform linux/amd64 -f - -t glebmark/cluster-agent:dev . <<'EOF'
FROM gcr.io/distroless/static-debian12:nonroot
COPY cluster-agent-linux /cluster-agent
ENTRYPOINT ["/cluster-agent"]
EOF

echo "==> Pushing image..."
DIGEST=$(docker push glebmark/cluster-agent:dev | grep "digest:" | awk '{print $3}')
echo "==> Pushed digest: $DIGEST"

echo "==> Rolling out with exact digest..."
kubectl set image deployment/cluster-agent agent=glebmark/cluster-agent@"$DIGEST" -n cluster-agent
kubectl -n cluster-agent rollout status deployment/cluster-agent --timeout=2m

echo "==> Cleaning up..."
rm cluster-agent-linux

echo "==> Done."
