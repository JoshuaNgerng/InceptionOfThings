#!/bin/bash
set -eux

apt-get update
apt-get install -y curl

# Install K3s server with kubeconfig readable by all users
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

# Wait until K3s API is healthy
echo "Waiting for K3s API..."
until curl -k https://127.0.0.1:6443/healthz; do
  echo "API not ready, waiting..."
  sleep 5
done

# Ensure kubectl symlink exists
ln -sf /usr/local/bin/k3s /usr/local/bin/kubectl

# Allow normal user to use kubectl
mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube


echo "Server setup complete"

# Serve token for worker with http server
echo "Initalizing server to give token"
cp /var/lib/rancher/k3s/server/node-token /vagrant/token
cd /vagrant
chmod +r token
python3 -m http.server 80