#!/bin/bash

set -e

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
# $(k3d kubeconfig write mycluster)

echo "K3d is ready."

echo "Create cluster for p3"

k3d cluster create p3 -p "8888:8888@loadbalancer" -p "8080:80@loadbalancer"
kubectl config use-context p3

echo "Creating namespace..."
# 1. Namespace (already done)
kubectl create namespace argocd || true
kubectl create namespace dev || true

# 2. Config ArgoCD
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# Wait for CRDs first (ensure API server reconginze new argocd resource is being resigtered) 
kubectl wait --for=condition=Established crd/applications.argoproj.io --timeout=60s
# Then ensure deployments are rolled out
kubectl rollout status deployment/argocd-server -n argocd --timeout=300s
kubectl rollout status deployment/argocd-repo-server -n argocd --timeout=300s
kubectl rollout status deployment/argocd-application-controller -n argocd --timeout=300s
# final port forwarding to access on local broswer
kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8443:443

# 3. Config dev 
kubectl apply -f ./confs/application.yaml
kubectl wait --for=condition=available deployment/iot-playground -n dev --timeout=120s

echo "Deployment finished."

echo "Cluster status:"
kubectl get nodes

echo "Services:"
kubectl get svc -n apps

echo "PVC:"
kubectl get pvc -n apps

echo "Pods:"
kubectl get pods -n apps -o wide
