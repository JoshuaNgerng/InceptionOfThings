#!/bin/bash

set -e

# 1. Cluster Creation
# k3d context is usually prefixed with 'k3d-'
k3d cluster create p3 -p "8888:8888@loadbalancer" -p "8080:80@loadbalancer" || echo "Cluster already exists, skipping..."
kubectl config use-context k3d-p3

echo "Creating namespaces..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -

# 2. Install ArgoCD
echo "Installing ArgoCD..."
# Removed --server-side to avoid the metadata length error
kubectl create -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml || \
kubectl replace -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for ArgoCD CRDs..."
kubectl wait --for=condition=Established crd/applications.argoproj.io --timeout=60s

# 2b. Needed when repo-server clones http://gitlab.local:8000/... from a sibling k3d cluster on the same Docker host.
# Override IP if docker0 is not 172.17.0.1 on your machine.
: "${GITLAB_LOCAL_BRIDGE_IP:=172.17.0.1}"
echo "Patching argocd-repo-server hostAliases (gitlab.local → ${GITLAB_LOCAL_BRIDGE_IP})..."
kubectl wait --for=condition=Available deployment/argocd-repo-server -n argocd --timeout=300s
kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge -p \
  '{"data":{"reposerver.allow.insecure.git.repos":"true"}}'
kubectl patch deployment argocd-repo-server -n argocd --type strategic -p \
  "{\"spec\":{\"template\":{\"spec\":{\"hostAliases\":[{\"ip\":\"${GITLAB_LOCAL_BRIDGE_IP}\",\"hostnames\":[\"gitlab.local\"]}]}}}}"
kubectl rollout status deployment/argocd-repo-server -n argocd --timeout=300s

# 3. Config dev (Argo Application)
echo "Applying ArgoCD Application Manifest..."
kubectl apply -f ./confs/application.yaml

# 4. Wait loop for ArgoCD Application to be Ready
# This ensures everything is Ready before we create the tunnel and show credentials
echo "Waiting for all pods in 'argocd' namespaces to be Ready..."

# Wait for ArgoCD Core
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

echo "Pods are ready."

# 5. Final Diagnostics
echo "--- Cluster Status ---"
kubectl get nodes
echo "--- Pods ---"
kubectl get pods -n argocd -o wide

# 6. Credentials and Foreground Tunnel
echo "---------------------------------------------------"
echo "ArgoCD Admin Password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
echo "---------------------------------------------------"

echo "Starting Port-forward (FOREGROUND)..."
echo "URL: https://<your-host>:8443 (Use 'admin' + password above)"
echo "Press Ctrl+C to stop the tunnel and exit the script."
echo "---------------------------------------------------"

# This command stays in the foreground and blocks the script from exiting
kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8443:443
