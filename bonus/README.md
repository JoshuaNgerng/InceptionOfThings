# 🚀 GitLab on Kubernetes (K3s)

This project provisions a local Kubernetes cluster using K3s, and deploys a self-hosted GitLab instance with supporting components:

- PostgreSQL (StatefulSet)
- Redis (Deployment)
- GitLab application (Deployment)
- Kubernetes Services
- Ingress (Traefik via K3s)

## 🧱 Architecture Overview

The environment is fully automated and consists of:

- K3s Kubernetes cluster
- Applications deployed via kubectl manifests
  
*Components*
- PostgreSQL
  - Deployed as a StatefulSet
  - Uses persistent volume claims (PVCs)
  - Stores GitLab metadata
- Redis
  - Deployed as a Deployment
  - Used as cache/session store for GitLab
- GitLab
  - Deployed as a Deployment
  - Connects to PostgreSQL and Redis
- Networking
  - Kubernetes Services for internal communication
  - Ingress handled by K3s default ingress controller (Traefik)


## 📦 Project Structure

```
.
├── scripts/
│   └── provision.sh
├── configs/
│   ├── postgres-statefulset.yaml
│   ├── postgres-service.yaml
│   ├── redis-deployment.yaml
│   ├── gitlab-deployment.yaml
│   ├── services.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   └── secret.yaml
```

## 🚀 Setup Instructions

### 1. Start the k3s server

*at the root (bonus) directory*
*Run scripts/startup.sh*

### 2. Verify server status

```
kubectl get nodes
kubectl get pods -n apps
```

### 🌐 Accessing GitLab

You can access GitLab using:

Option 1: Via VM IP
```
http://192.168.56.110
```

Option 2: Via Port Forwarding (if configured)
```
http://localhost:8080
```

Option 3: Via Ingress

If ingress is configured properly:
```
http://<VM-IP>
```
Example:
```
http://192.168.56.110
```


## 🧪 Testing the Setup
1. Check cluster status
   - kubectl get nodes
2. Check all pods
   - Deployment of a full GitLab stack locally

*Expected:*

    - postgres-0 → Running
    - redis → Running
    - gitlab → Running

3. Check services
```
kubectl get svc -n apps
```

4. Check persistent storage
```
kubectl get pvc -n apps
```
*Expected:*

    A PVC created for PostgreSQL (from StatefulSet)

5. Verify Ingress
```
kubectl get ingress -n apps
```

## 📊 Architecture Diagram

Here’s a simple high-level diagram of your setup:

```

        ┌──────────────────────────────────────────────┐
        │                VM or Host                    │
        │            (Ubuntu + K3s Cluster)            │
        │                                              │
        │   Private IP: 192.168.56.110                 │
        │                                              │
        │   ┌──────────────────────────────────────┐   │
        │   │         K3s Kubernetes Cluster       │   │
        │   │                                      │   │
        │   │   ┌───────────────┐                  │   │
        │   │   │   Ingress     │                  │   │
        │   │   │ (Traefik)     │                  │   │
        │   │   └──────┬────────┘                  │   │
        │   │          │                           │   │
        │   │          ▼                           │   │
        │   │   ┌───────────────┐                  │   │
        │   │   │  GitLab Pod   │                  │   │
        │   │   │ (Deployment)  │                  │   │
        │   │   └──────┬────────┘                  │   │
        │   │          │                           │   │
        │   │   ┌──────▼──────┐    ┌─────────────┐ │   │
        │   │   │ PostgreSQL  │    │   Redis     │ │   │
        │   │   │ StatefulSet │    │ Deployment  │ │   │
        │   │   └──────┬──────┘    └─────┬───────┘ │   │
        │   │          │                 │         │   │
        │   │   ┌──────▼─────────────────▼──────┐  │   │
        │   │   │        Services (ClusterIP)   │  │   │
        │   │   └───────────────────────────────┘  │   │
        │   │                                      │   │
        │   │   ┌──────────────────────────────┐   │   │
        │   │   │ Persistent Volume (PVC)      │   │   │
        │   │   │ (Postgres data storage)      │   │   │
        │   │   └──────────────────────────────┘   │   │
        │   └──────────────────────────────────────┘   │
        └──────────────────────────────────────────────┘
```
## 🗄️ Data Persistence
- PostgreSQL uses a StatefulSet with volumeClaimTemplates
- Each pod gets its own persistent volume
- Data survives:
    - Pod restarts
    - Node restarts (within the VM)

Storage is backed by K3s local-path provisioner.

## 🔑 Configuration

### Secrets

Sensitive values (e.g. PostgreSQL password) are stored in Kubernetes Secrets:

- app-secret

### ConfigMaps

Used for non-sensitive configuration such as:

- GitLab environment variables

## ⚠️ Important Notes

1. StatefulSet vs Deployment for Postgres
- PostgreSQL is deployed as a StatefulSet
- Ensures:
    - Stable identity
    - Persistent storage per pod
    - Safe restarts
2. Ingress Controller

    K3s includes Traefik by default.

    - No additional installation required
    - Handles routing traffic to services

3. Resource Requirements

    Recommended VM specs:

    - RAM: ≥ 8 GB
    - CPU: ≥ 4 cores

    GitLab is resource-intensive.

4. Single-node Cluster

    This setup is designed for:

    - Development
    - Testing
    - Learning

    - Not production-ready.

## 🛠️ Useful Commands

Restart a deployment
```
kubectl rollout restart deployment gitlab -n apps
```
View logs
```
kubectl logs -n apps <pod-name>
```
Describe resources
```
kubectl describe pod <pod-name> -n apps
```

## 🧹 Tear Down

To scale down database
```
kubectl scale statefulset <postgres-statefulset-name> --replicas=0 -n <namespace>
```

To scale back up
```
kubectl scale statefulset <postgres-statefulset-name> --replicas=1 -n <namespace>
```

To pause server without removing data

on server side
```
sudo systemctl stop k3s
```
if on worker side
```
sudo systemctl stop k3s-agent
```

To resume server
```
sudo systemctl start k3s
```

To delete all database
```
kubectl get pvc --all-namespaces
kubectl delete pvc <pvc-name> -n <namespace>
```


## 🧪 Troubleshooting Guide
### 🔍 1. Pods stuck in Pending

*Possible causes:*

- PVC not bound
    - Insufficient resources
    - Storage class issues

*Check:*

```
kubectl get pvc -n apps
kubectl describe pod <pod-name> -n apps
```

*Fix:*

- Ensure K3s local-path storage is working
- Verify PVC size requests are valid

### 🔍 2. PostgreSQL not starting

Check logs:

```
kubectl logs -n apps postgres-0
````

Common issues:

- Wrong environment variables
- Missing secret (app-secret)
- Volume permission issues

Fix:

- Verify secret exists:
```
kubectl get secret -n apps
```

### 🔍 3. GitLab cannot connect to database

Symptoms:

- GitLab pods crashlooping
- Errors about DB connection

Check:
```
kubectl logs -n apps <gitlab-pod>
```

Fix:

- Ensure:
    - Postgres service name matches (postgres)
    - Correct credentials in secrets
    - Postgres pod is running

### 🔍 4. Ingress not accessible

Check:

```
kubectl get ingress -n apps
kubectl describe ingress -n apps
```

Common issues:

- Incorrect host/IP
- Ingress rules misconfigured
- Service not exposed correctly

Fix:

Confirm you're accessing via:

    http://192.168.56.110
Ensure Traefik is running (default in K3s)

### 🔍 5. Services not reachable internally

Check:
```
kubectl get svc -n apps
```
Fix:

- Ensure:
    - Service selector matches pod labels
    - Correct ports are defined

### 🔍 6. PVC not binding

Check:
```
kubectl get pvc -n apps
```
Fix:

- Verify:

    - Storage class exists:
        ```
        kubectl get storageclass
        ```
    - K3s local-path provisioner is installed

### 🔍 7. Pod CrashLoopBackOff

Check logs:

```
kubectl describe pod <pod-name> -n apps
kubectl logs <pod-name> -n apps
```

Common causes:

- Missing environment variables
- Misconfigured secrets/configmaps
- Application startup failure

### 🧠 Debugging Workflow (Recommended)

When something fails:

1. Check pods:
```
kubectl get pods -n apps
```
2. Describe failing pod:
```
kubectl describe pod <pod>
```
3. Check logs:
```
kubectl logs <pod>
```
4. Verify services:
```
kubectl get svc -n apps
```
5. Verify ingress:
```
kubectl get ingress -n apps
```

## 📌 Summary

- This project demonstrates:

    - Kubernetes cluster provisioning using K3s
    - Stateful workloads using StatefulSets
    - Service discovery and networking in Kubernetes
    - Ingress-based routing with Traefik
    - Deployment of a full GitLab stack locally
