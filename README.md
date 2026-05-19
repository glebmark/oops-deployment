# dev-infra

Personal GKE cluster in `gleb-oops` for local development and testing.

**Cost**: ~$7-10/month (single spot e2-medium node, zonal cluster = free management fee).

## Prerequisites

Switch gcloud to your personal project and create the Terraform state bucket:

```bash
gcloud config set project gleb-oops

# Enable required APIs
gcloud services enable container.googleapis.com compute.googleapis.com

# Create state bucket (one-time)
gsutil mb -p gleb-oops -l us-east1 gs://tfstate-gleb-oops
```

## Apply order

Modules have dependencies — apply in this order:

```bash
# 1. VPC network
cd network && terragrunt apply && cd ..

# 2. NAT gateway (lets private nodes pull images from the internet)
cd nat && terragrunt apply && cd ..

# 3. GKE cluster
cd cluster && terragrunt apply && cd ..
```

Or apply all at once (terragrunt resolves deps):

```bash
terragrunt run-all apply
```

## Connect kubectl

After the cluster is up:

```bash
gcloud container clusters get-credentials gleb-dev \
  --zone us-east1-c \
  --project gleb-oops
```

## Deploy the oops agent

Manifests live in `manifests/`. Apply in order:

```bash
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/rbac.yaml

# Create the secret with real values (never apply manifests/secret.yaml directly)
kubectl -n cluster-agent create secret generic cluster-agent \
  --from-literal=api-url=https://YOUR_NGROK_URL \
  --from-literal=agent-token=YOUR_TOKEN

kubectl apply -f manifests/deployment.yaml
```

To update the secret later without touching other resources:

```bash
kubectl -n cluster-agent create secret generic cluster-agent \
  --from-literal=api-url=https://NEW_NGROK_URL \
  --from-literal=agent-token=YOUR_TOKEN \
  --dry-run=client -o yaml | kubectl apply -f -
```

To redeploy after a new image push:

```bash
kubectl -n cluster-agent rollout restart deployment/cluster-agent
```

## Tear down

```bash
terragrunt run-all destroy
```

## Notes

- Spot node can be evicted at any time. GKE reschedules pods within ~1 min. The agent handles reconnection automatically.
- The cluster is zonal (single zone `us-east1-c`) — no HA, which is fine for dev.
- Workload Identity is enabled by default on GKE. The cluster-agent K8s ServiceAccount is bound to `roles/container.viewer` via Direct Workload Identity (principal:// IAM binding on `gleb-oops` — no GCP service account needed).
