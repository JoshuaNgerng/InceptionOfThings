#!/bin/bash

set -e

# k3d writes kubeconfig to the default file (~/.kube/config).

echo "Create cluster for bonus"

# 1. Make cluster for bonus
k3d cluster create bonus -p "8000:80@loadbalancer"
# k3d names the context k3d-<clustername>, e.g. k3d-bonus (see p3/scripts/startup.sh)
kubectl config use-context k3d-bonus

echo "Creating namespace..."
# 2. Namespace (already done)
kubectl create namespace gitlab || true

# 3. Secret (required by postgres — envFrom secretKeyRef)
echo "Applying secret"
kubectl apply -f ./confs/secret.yaml

# 4. Config
echo "Applying config map"
kubectl apply -f ./confs/configmap.yaml

# 5. Postgres (StatefulSet)
echo "Applying postgres "
kubectl apply -f ./confs/postgres-service.yaml
kubectl apply -f ./confs/postgres-statefulset.yaml
kubectl rollout status statefulset/postgres -n gitlab --timeout=120s

# 6. Redis
echo "Applying redis"
kubectl apply -f ./confs/redis-deployment.yaml
kubectl wait --for=condition=available deployment/redis -n gitlab --timeout=120s

# 7. Services (so gitlab can connect)
echo "Applying service"
kubectl apply -f ./confs/service.yaml

# 8. Application LAST
echo "Applying gitlab"
kubectl apply -f ./confs/gitlab-deployment.yaml

# 9. Ingress (optional, after service works)
echo "Applying ingress"
kubectl apply -f ./confs/ingress.yaml

echo "Deployment finished."

echo "Cluster status:"
kubectl get nodes

echo "Services:"
kubectl get svc -n gitlab

echo "PVC:"
kubectl get pvc -n gitlab

echo "Pods:"
kubectl get pods -n gitlab -o wide
