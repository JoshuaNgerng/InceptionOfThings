#!/bin/bash

set -e

cd "$(dirname "$0")/.."

# 1. Cluster creation (idempotent: skip if cluster already exists)
# k3d writes kubeconfig to ~/.kube/config; context name is k3d-<clustername>
k3d cluster create bonus -p "8000:80@loadbalancer" || echo "Cluster already exists, skipping..."
kubectl config use-context k3d-bonus

echo "Creating namespace..."
kubectl create namespace gitlab --dry-run=client -o yaml | kubectl apply -f -

# 2. Secret (Postgres + GitLab root password on first DB init)
echo "Applying secret..."
kubectl apply -f ./confs/secret.yaml

# 3. Config
echo "Applying config map..."
kubectl apply -f ./confs/configmap.yaml

# 4. Postgres
echo "Applying postgres..."
kubectl apply -f ./confs/postgres-service.yaml
kubectl apply -f ./confs/postgres-statefulset.yaml
kubectl rollout status statefulset/postgres -n gitlab --timeout=120s

# 5. Redis
echo "Applying redis..."
kubectl apply -f ./confs/redis-deployment.yaml
kubectl wait --for=condition=available deployment/redis -n gitlab --timeout=120s

# 6. Services
echo "Applying services..."
kubectl apply -f ./confs/service.yaml

# 7. GitLab (after DB + Redis)
echo "Applying GitLab..."
kubectl apply -f ./confs/gitlab-deployment.yaml

# 8. Ingress
echo "Applying ingress..."
kubectl apply -f ./confs/ingress.yaml

# 9. Wait for GitLab (first boot can take many minutes)
echo "Waiting for GitLab rollout (first run can take 15+ minutes)..."
kubectl rollout status deployment/gitlab -n gitlab --timeout=2400s

# 10. Final diagnostics
echo "--- Cluster status ---"
kubectl get nodes
echo "--- Services (gitlab) ---"
kubectl get svc -n gitlab
echo "--- PVC ---"
kubectl get pvc -n gitlab
echo "--- Pods ---"
kubectl get pods -n gitlab -o wide

# 11. Credentials (same idea as p3 ArgoCD password block)
echo "---------------------------------------------------"
echo "GitLab sign-in"
echo "  Username: root"
echo -n "  Initial password: "
kubectl get secret app-secret -n gitlab -o jsonpath='{.data.GITLAB_ROOT_PASSWORD}' | base64 -d
echo
echo "  URL:      http://gitlab.local:8000"
echo "  Admin UI: http://gitlab.local:8000/-/admin (after signing in as root)"
echo "Note: GITLAB_ROOT_PASSWORD is applied only on the first GitLab database"
echo "      initialization. If GitLab data already exists, use your existing"
echo "      root password or reset it (see GitLab docs: reset root password)."
echo "---------------------------------------------------"
