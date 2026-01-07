#!/bin/bash
set -e

SERVER_IP="192.168.56.110"

echo "[INFO] Waiting for server token"
while [ ! -f /vagrant/k3s-token ]; do
  sleep 2
done

K3S_TOKEN=$(cat /vagrant/k3s-token)

echo "[INFO] Installing K3s agent"
curl -sfL https://get.k3s.io | K3S_URL="https://${SERVER_IP}:6443" \
  K3S_TOKEN="${K3S_TOKEN}" sh -
