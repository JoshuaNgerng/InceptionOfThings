#!/bin/bash
set -e

echo "[INFO] Updating system"
apt-get update -y
apt-get upgrade -y

echo "[INFO] Disabling swap (required for Kubernetes)"
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

echo "[INFO] Installing dependencies"
apt-get install -y \
  curl \
  apt-transport-https \
  ca-certificates \
  gnupg \
  net-tools \
  lsb-release

echo "[INFO] Enabling required kernel modules"
modprobe overlay
modprobe br_netfilter

cat <<EOF >/etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system
