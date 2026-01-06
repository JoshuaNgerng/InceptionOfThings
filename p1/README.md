files
common.sh

Shared setup

OS-level configuration

Same for all nodes

install_k3s_server.sh

Control-plane logic

kubectl installation

Token generation

install_k3s_agent.sh

Worker-specific logic

Join cluster using token

✔ Cleaner
✔ Easier to debug
✔ Easier to scale later


🚨 Problems with synced folders in Kubernetes

Kubernetes (and K3s) expects:

Correct Linux permissions

Native filesystem behavior

Inotify support (file watching)

VirtualBox shared folders have issues:

❌ Permission mismatches
❌ File locking problems
❌ Slow I/O
❌ Issues with container volumes

This can cause:

Pods failing to start

Volume mount errors

Weird crashes

🧩 Bonus: When SHOULD you use synced folders?

Use them for:

Web development

Code editing

Logs

Non-Kubernetes projects

Avoid them for:

Kubernetes

Databases

High I/O workloads

“Vagrant synced folders allow sharing files between the host and the virtual machine. However, VirtualBox shared folders can cause permission and filesystem issues, especially with Kubernetes. Therefore, we disable the default synced folder to ensure system stability and follow best practices.”

