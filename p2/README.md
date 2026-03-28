# K3s Multi-Application Deployment with Vagrant

## Project Overview

This project deploys **three simple web applications** inside a **K3s Kubernetes cluster** running on a **single virtual machine** managed by Vagrant.

The applications are exposed using **Kubernetes Ingress with host-based routing**.
Depending on the **Host header** used in the request, the server returns a different application.

Routing behavior:

| Host           | Result                      |
| -------------- | --------------------------- |
| app1.com       | Displays **app1**           |
| app2.com       | Displays **app2**           |
| Any other host | Displays **app3** (default) |

Application **app2** runs with **3 replicas** to demonstrate Kubernetes scaling.

---

# Architecture

```
Host Machine
     │
     │ 192.168.56.110
     ▼
Vagrant Virtual Machine
(Ubuntu + K3s)

K3s Cluster
│
├── app1 Deployment (1 replica)
├── app2 Deployment (3 replicas)
├── app3 Deployment (1 replica)
│
├── Services
│     ├── app1-service
│     ├── app2-service
│     └── app3-service
│
└── Ingress (Traefik)
      ├── app1.com → app1
      ├── app2.com → app2
      └── default → app3
```

---

# Project Structure

```
project/
│
├── Vagrantfile
│
├── scripts/
│   └── provision.sh
│
└── configs/
    ├── app1-deployment.yaml
    ├── app2-deployment.yaml
    ├── app3-deployment.yaml
    ├── services.yaml
    └── ingress.yaml
```

---

# Requirements

Before running the project, install:

* Vagrant
* VirtualBox
* Git (optional)

Recommended system resources:

* 4GB RAM available
* 10GB disk space

---

# Setup Instructions

## 1 Start the virtual machine

Run:

```
vagrant up
```

This will automatically:

1. Create the virtual machine
2. Install K3s
3. Create the Kubernetes namespace
4. Deploy the applications
5. Configure services and ingress

Provisioning may take **1–3 minutes**.

---

## 2 Access the virtual machine (optional)

```
vagrant ssh
```

You can check the cluster with:

```
kubectl get nodes
kubectl get pods -A
kubectl get svc -A
kubectl get ingress -A
```

---

# Host Configuration

To access the applications from your host machine, add entries to your hosts file.

## Linux / macOS

Edit:

```
/etc/hosts
```

Add:

```
192.168.56.110 app1.com
192.168.56.110 app2.com
192.168.56.110 app3.com
192.168.56.110 test.com
```

*add another stuff for linux vm if diff

---

## Windows

Edit:

```
C:\Windows\System32\drivers\etc\hosts
```

Add the same entries but use the IP of the host VM.


---

# Testing the Applications

After the VM is running and the hosts file is updated, open a browser.

### Test Application 1

```
http://app1.com
```

Expected output:

```
app1
```

---

### Test Application 2

```
http://app2.com
```

Expected output:

```
app2
```

Application **app2 runs 3 replicas**, demonstrating Kubernetes load balancing.

---

### Default Application

Any other host will route to **app3**.

Example:

```
http://test.com
```

Expected output:

```
app3
```

---

# Testing with curl (optional)

You can also test using curl:

```
curl -H "Host: app1.com" 192.168.56.110
curl -H "Host: app2.com" 192.168.56.110
curl -H "Host: anything.com" 192.168.56.110
```

Expected results:

```
app1
app2
app3
```

---

# Useful Kubernetes Commands

Check pods:

```
kubectl get pods -n apps
```

Check services:

```
kubectl get svc -n apps
```

Check ingress:

```
kubectl get ingress -n apps
```

Describe resources:

```
kubectl describe ingress -n apps
kubectl describe pod <pod-name>
```

View logs:

```
kubectl logs <pod-name>
```

---

# Stopping the Environment

To stop the VM:

```
vagrant halt
```

To destroy it completely:

```
vagrant destroy
```

---

# Troubleshooting

### Pods not starting

Check:

```
kubectl get pods -A
kubectl describe pod <pod-name>
```

---

### Ingress not working

Verify:

```
kubectl get ingress -A
kubectl get svc -A
```

Ensure the hosts file is correctly configured.

---

# Key Concepts Demonstrated

This project demonstrates:

* Infrastructure automation using **Vagrant**
* Lightweight Kubernetes with **K3s**
* Kubernetes **Deployments**
* Kubernetes **Services**
* Kubernetes **Ingress**
* **Host-based routing**
* **Scaling applications with replicas**

---

