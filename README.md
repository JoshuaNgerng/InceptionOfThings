# Project description

This project utilize vagrant and kubclt
to learn how to automate vm setup and automate deployment and reliable service and monitoring with kubeclt

## p1

a **Vagrant** setup for two vm
one server vm to host the Kubernetes API server
one worker to connect to the API server in server vm
server vm act as management/control VM, worker runs only workloads (pods) no access to management
better security
|-- limit the opportunity for attack
|-- only admin can access server vm for monitoring and change

## p2

a **Vagrant** setup for one vm, but a kubctl with many pods setup
**ingress** layer to ensure the right domain is directed to the right service pod

## p3

Utilizes **K3d** (Kubernetes in Docker) to spin up a local cluster and
**Argo CD** to implement a GitOps continuous delivery pipeline.

## bonus

a **K3d** setup with a robust kubclt setup for hosting gitlab
a service layer to give gitlab content
a redis layer for caching
a postgres layer with statefulset to keep track of data 
a ingress layer to ensure connection to the service pod

