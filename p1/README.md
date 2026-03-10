# Project Overview

This project sets up a 2-node Kubernetes cluster using K3s and Vagrant.

The infrastructure consists of

| Machine | Hostname | Role          | IP             |
| ------- | -------- | ------------- | -------------- |
| Server  | userS    | Control Plane | 192.168.56.110 |
| Worker  | userSW   | Worker Node   | 192.168.56.111 |

The Server node runs the K3s control-plane, while the Worker node runs the K3s agent.

The cluster is created automatically using Vagrant provisioning scripts.


## Requirements

Before running the project, install:

Vagrant

VirtualBox

Check installation:

```
vagrant --version
```

```
virtualbox --help
```

## Project Structure

```
.
├── Vagrantfile
├── README.md
└── scripts
    ├── install_server.sh
    └── install_worker.sh
```

Vagrantfile → defines the virtual machines

install_server.sh → installs K3s server

install_worker.sh → installs K3s agent

## VM Specifications

Each VM is configured with minimal resources:

| Resource | Value        |
| -------- | ------------ |
| CPU      | 1            |
| RAM      | 2048 MB      |
| OS       | Ubuntu 22.04 |


Network configuration:

| Node   | IP             |
| ------ | -------------- |
| Server | 192.168.56.110 |
| Worker | 192.168.56.111 |


## Starting the Cluster

From the project directory run:

```
vagrant up
```

This will:

1) Create both virtual machines

2) Install K3s server on userS

3) Install K3s agent on userSW

4) Join the worker to the cluster automatically

## Connecting to the Machines

Connect using SSH:

Server:

```
vagrant ssh userS
```

Worker:

```
vagrant ssh userSW
```

No password is required.

## Verifying the Cluster

All Kubernetes commands are executed from the Server node.

### Check nodes

```
kubectl get nodes
```

|NAME   |  STATUS |  ROLES         | AGE   |  VERSION |
| ----  | ------- | -------------- | ------| -------- |
|users  |  Ready  |  control-plane |       |          |
|usersw |  Ready  |  <none>        |       |          |

### Detailed node information

```
kubectl get nodes -o wide
```

This shows:

- node IP

- container runtime

- Kubernetes version

### Check system pods

```
kubectl get pods -A
```

Important system pods should be Running, for example:

- coredns

- local-path-provisioner

- metrics-server

- traefik

### Cluster information

```
kubectl cluster-info
```

Displays the Kubernetes control plane endpoints.

## Checking the Server Node

On userS verify that the K3s service is running:

```
sudo systemctl status k3s
```
View logs:
```
sudo journalctl -u k3s
```

## Checking the Worker Node

On userSW verify the agent service:

```
sudo systemctl status k3s-agent
```

View logs:
```
sudo journalctl -u k3s-agent
```

## Stopping the Cluster

Stop the virtual machines:

```
vagrant halt
```

Destroy the cluster:

```
vagrant destroy
```

## Network Verification

Check IP configuration on both machines:

```
ip a
```

Expected IPs:

Server:

```
192.168.56.110
```

Worker:

```
192.168.56.111
```

## Notes

- kubectl is configured only on the Server node

- The Worker node runs k3s-agent and does not host the API server

- All cluster management commands must be executed on userS