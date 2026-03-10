vagrant setup
vagrant up (start vms)
vagrant halt (pause vms)
vagrant destroy (shutdown and remove vms)

check ip in both server


check server vm
vagrant ssh userS

check kubectl 
kubectl get nodes
kubectl get pods -A
kubectl get pods -o wide
kubectl cluster-info

check worker vm
sudo systemctl status k3s-agent