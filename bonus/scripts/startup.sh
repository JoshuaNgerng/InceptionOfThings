#!/bin/bash
set -e

cd "$(dirname "$0")/.."

# 1. Cluster creation (idempotent: skip if cluster already exists)
# k3d writes kubeconfig to ~/.kube/config; context name is k3d-<clustername>
# 8GB VM tuning: reserve some RAM for the host, split cluster across server+agent.
k3d cluster create bonus \
  --servers 1 --agents 1 \
  --servers-memory 3584m --agents-memory 2560m \
  -p "8000:80@loadbalancer" || echo "Cluster already exists, skipping..."
kubectl config use-context k3d-bonus

echo "Creating namespace..."
kubectl create namespace gitlab --dry-run=client -o yaml | kubectl apply -f -

# 2. Secret (runtime configurable)
: "${POSTGRES_PASSWORD:=Gitlabdev1!}"

kubectl -n gitlab create secret generic app-secret \
  --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

# 3. Postgres
echo "Applying postgres..."
kubectl apply -f ./confs/postgres-service.yaml
kubectl apply -f ./confs/postgres-statefulset.yaml
kubectl rollout status statefulset/postgres -n gitlab --timeout=120s

# 4. Redis
echo "Applying redis..."
kubectl apply -f ./confs/redis-deployment.yaml
kubectl wait --for=condition=available deployment/redis -n gitlab --timeout=120s

# 5. Services
echo "Applying services..."
kubectl apply -f ./confs/service.yaml

# 6. GitLab (after DB + Redis)
echo "Applying GitLab..."
kubectl apply -f ./confs/gitlab-deployment.yaml

# 7. Ingress
echo "Applying ingress..."
kubectl apply -f ./confs/ingress.yaml

# 8. Wait for GitLab (first boot can take many minutes)
: "${GITLAB_ROLLOUT_TIMEOUT:=1800}"
echo "Waiting for GitLab rollout (timeout ${GITLAB_ROLLOUT_TIMEOUT}s; first boot may take 10-15 minutes)..."
kubectl rollout status deployment/gitlab -n gitlab --timeout="${GITLAB_ROLLOUT_TIMEOUT}s"

# 9. Final diagnostics
echo "--- Cluster status ---"
kubectl get nodes
echo "--- Services (gitlab) ---"
kubectl get svc -n gitlab
echo "--- PVC ---"
kubectl get pvc -n gitlab
echo "--- Pods ---"
kubectl get pods -n gitlab -o wide

# 10. Credentials hint
echo "---------------------------------------------------"
echo "GitLab"
echo "  URL:      http://gitlab.local:8000"
echo "  Sign in:  username root"
echo "Read the initial root password from the pod:"
echo '  kubectl exec -n gitlab deploy/gitlab -- cat /etc/gitlab/initial_root_password'
echo "To change the root password, run:"
echo '  kubectl exec -it -n gitlab deploy/gitlab -- gitlab-rake "gitlab:password:reset[root]"'
echo "---------------------------------------------------"
