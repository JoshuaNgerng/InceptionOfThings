#!/bin/bash

set -e

echo "Updating system..."
apt-get update -y

echo "Installing curl..."
apt-get install -y curl

echo "Installing K3s..."
curl -sfL https://get.k3s.io | sh -

echo "Waiting for K3s to start..."
sleep 10

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml


# Wait until node is ready
until kubectl get node >/dev/null 2>&1; do
  echo "Waiting for Kubernetes API..."
  sleep 5
done

echo "K3s is ready."

echo "Creating namespace..."
# 1. Namespace (already done)
kubectl create namespace apps || true

# 2. Config (if using)
kubectl apply -f /vagrant/configs/configmap.yaml
# kubectl apply -f /vagrant/configs/secret.yaml


# 3. Postgres (StatefulSet)
kubectl apply -f /vagrant/configs/postgres-service.yaml
kubectl apply -f /vagrant/configs/postgres-statefulset.yaml
kubectl rollout status statefulset/postgres -n apps --timeout=120s

# 4. Redis 
kubectl apply -f /vagrant/configs/redis-deployment.yaml
kubectl wait --for=condition=available deployment/redis -n apps --timeout=120s

# 5. Services (so apps can connect)
kubectl apply -f /vagrant/configs/services.yaml

# 6. Application LAST
kubectl apply -f /vagrant/configs/gitlab-deployment.yaml

# 7. Ingress (optional, after service works)
kubectl apply -f /vagrant/configs/ingress.yaml

echo "Deployment finished."

echo "Cluster status:"
kubectl get nodes

echo "Services:"
kubectl get svc -n apps

echo "PVC:"
kubectl get pvc -n apps

echo "Pods:"
kubectl get pods -n apps -o wide
