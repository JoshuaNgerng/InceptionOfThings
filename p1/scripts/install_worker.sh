#!/bin/bash

apt-get update
apt-get install -y curl

echo "Waiting for server token..."

while [ ! -f /vagrant/token ]; do
  echo "Token not ready yet"
  sleep 5
done

TOKEN=$(cat /vagrant/token)

echo "Waiting for Kubernetes API..."

until curl -k https://192.168.56.110:6443/healthz; do
  echo "API not ready"
  sleep 5
done

echo "Installing k3s agent..."

curl -sfL https://get.k3s.io | \
K3S_URL=https://192.168.56.110:6443 \
K3S_TOKEN=$TOKEN \
sh -
