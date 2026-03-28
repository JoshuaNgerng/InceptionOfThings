#!/bin/bash

apt-get update
apt-get install -y curl wget

echo "Waiting for server token..."

URL="http://192.168.56.110:8000"

until curl -s "$URL" > /dev/null; do
  echo "Waiting for token server..."
  sleep 2
done

TOKEN=$(wget "$URL/token")

cat $TOKEN

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
