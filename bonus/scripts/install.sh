#!/bin/bash

set -e

echo "Starting Installation of Dependencies"

# System Updates and Prerequisites
echo "Checking system prerequisites..."
# apt-get update is safe to run multiple times
sudo apt-get update -y
if ! command -v curl &> /dev/null; then
    echo "Installing curl and certificates..."
    sudo apt-get install -y curl ca-certificates
else
    echo "-> curl is already installed. Skipping."
fi

# Docker Installation
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh # Clean up installation files
else
    echo "-> Docker is already installed. Skipping."
fi

# Docker User Permissions
# Check if the user is already in the docker group to prevent redundant modifications
if ! groups $USER | grep -q '\bdocker\b'; then
    echo "Adding $USER to the docker group..."
    sudo usermod -aG docker $USER
    echo "-> ACTION REQUIRED: You will need to log out and log back in for group changes to take effect."
else
    echo "-> User $USER is already in the docker group. Skipping."
fi

# K3d Installation
if ! command -v k3d &> /dev/null; then
    echo "Installing K3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
else
    echo "-> K3d is already installed. Skipping."
fi

# Kubectl Installation
if ! command -v kubectl &> /dev/null; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl # Clean up downloaded binary
else
    echo "-> kubectl is already installed. Skipping."
fi

echo "Install complete! Please log out and log back in to apply group changes if you were added to the docker group."
