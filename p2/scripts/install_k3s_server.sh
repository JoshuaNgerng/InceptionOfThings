#!/bin/bash
set -e

echo "[INFO] Installing K3s server"

curl -sfL https://get.k3s.io | sh -s - \
  --write-kubeconfig-mode 644 \
  --node-ip 192.168.56.110

echo "[INFO] Installing kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

echo "[INFO] Saving K3s token for workers"
cat /var/lib/rancher/k3s/server/node-token > ~/k3s-token
