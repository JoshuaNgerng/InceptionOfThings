# Inception-of-Things: Part 3 (K3d & Argo CD)

This directory contains the configuration and deployment scripts for Part 3 of the Inception-of-Things project. It utilizes **K3d** (Kubernetes in Docker) to spin up a local cluster and **Argo CD** to implement a GitOps continuous delivery pipeline.

## Prerequisites

Before running any scripts, ensure your VirtualBox Host VM is configured correctly:
1. **Operating System:** A lightweight, headless Linux distribution (e.g., Debian 13 Netinst).
2. **Resources:** 1 CPU and 512 MB (or 1024 MB) of RAM.
3. **Network Adapters:**
   - **Adapter 1:** NAT (for internet access).
   - **Adapter 2:** Host-Only Adapter (configured with a static IP of `192.168.56.110`).

## Step 1: Bootstrapping the Server

The `install.sh` script is fully idempotent and prepares the fresh Debian VM by installing Docker, K3d, and kubectl.

1. Navigate to the scripts directory:
   ```bash
   cd p3/scripts
   ```
2. Make the script executable and run it:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

## Step 2: Provisioning the Cluster & Namespaces

Once the dependencies are installed, create the K3d cluster. We map port 8888 for our web application and port 8080 for standard HTTP traffic.

1. Create the cluster:
   ```bash
   k3d cluster create p3 -p "8888:8888@loadbalancer" -p "8080:80@loadbalancer"
   ```
2. Create the required namespaces for logical isolation:
   ```bash
   kubectl create namespace argocd
   kubectl create namespace dev
   ```

## Step 3: Deploying ArgoCD

ArgoCD handles our GitOps pipeline. We install it directly into its dedicated namespace.

1. Apply the official ArgoCD installation manifest:
   ```bash
   kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```
2. Wait for all ArgoCD pods to reach a `Running` state:
   ```bash
   kubectl get pods -n argocd
   ```

## Step 4: Accessing the ArgoCD UI

To access the ArgoCD web dashboard from the Windows host machine, we tunnel the traffic using kubectl port-forward and bind it to all network interfaces (0.0.0.0) so the Host-Only adapter can route it.

1. Start the secure port-forwarding tunnel (leave this running in its own terminal):
   ```bash
   kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8443:443
   ```
2. In a new terminal session, retrieve the auto-generated admin password:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
   ```
3. Open a browser on the host machine and navigate to: `https://192.168.56.110:8443`
4. Log in with the username `admin` and the password retrieved in the previous step.

## Step 5: The Application Manifests

Our application is defined declaratively using Kubernetes manifests stored in a separate public GitHub repository.

1. We define a `Deployment` to pull and run the `wil42/playground:v1` image in the `dev` namespace.
2. We define a `Service` to expose the application on port `8888`.
3. These manifests are pushed to the `main` branch, acting as the single source of truth for the application's desired state.

## Step 6: The Argo CD Application

To connect our GitHub repository to the cluster, we deploy an Argo CD `Application` resource.

1. The `application.yaml` file defines the source (our public GitHub repo) and the destination (the local `dev` namespace).
2. It is configured with `automated` sync policies (`prune` and `selfHeal`), ensuring the cluster strictly mirrors the GitHub repository at all times.
3. Once applied via `kubectl apply -f application.yaml`, Argo CD automatically deploys the application.
4. The running application can be accessed via **`http://192.168.56.110:8888`**.
