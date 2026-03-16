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
kubectl create namespace apps || true

echo "Applying Kubernetes manifests..."

kubectl apply -f /vagrant/configs/app1-deployment.yaml
kubectl apply -f /vagrant/configs/app2-deployment.yaml
kubectl apply -f /vagrant/configs/app3-deployment.yaml

kubectl apply -f /vagrant/configs/services.yaml

kubectl apply -f /vagrant/configs/ingress.yaml

echo "Deployment finished."

echo "Cluster status:"
kubectl get nodes
kubectl get pods -A

