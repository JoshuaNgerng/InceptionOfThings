#!/bin/bash

#!/bin/bash

set -e

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
# $(k3d kubeconfig write mycluster)

# Wait until node is ready
until kubectl get node >/dev/null 2>&1; do
  echo "Waiting for Kubernetes API Server..."
  sleep 5
done

echo "K3d is ready."

echo "Create cluster for bonus"

kubectl config use-context bonus

echo "Creating namespace..."
# 2. Namespace (already done)
kubectl create namespace apps || true

# 3. Config  
kubectl apply -f ./confs/configmap.yaml
# if have secret
# kubectl apply -f /vagrant/confs/secret.yaml

# 4. Postgres (StatefulSet)
kubectl apply -f ./confs/postgres-service.yaml
kubectl apply -f ./confs/postgres-statefulset.yaml
kubectl rollout status statefulset/postgres -n apps --timeout=120s

# 5. Redis 
kubectl apply -f ./confs/redis-deployment.yaml
kubectl wait --for=condition=available deployment/redis -n apps --timeout=120s

# 6. Services (so apps can connect)
kubectl apply -f ./confs/services.yaml

# 7. Application LAST
kubectl apply -f ./confs/gitlab-deployment.yaml

# 8. Ingress (optional, after service works)
kubectl apply -f ./confs/ingress.yaml

echo "Deployment finished."

echo "Cluster status:"
kubectl get nodes

echo "Services:"
kubectl get svc -n apps

echo "PVC:"
kubectl get pvc -n apps

echo "Pods:"
kubectl get pods -n apps -o wide
