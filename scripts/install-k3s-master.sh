#!/bin/bash
set -e

echo "Starting k3s master installation..."

# Update system packages
sudo apt update && sudo apt upgrade -y

# Install k3s on master node with disabled traefik (we'll use our own)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --cluster-init" sh -

# Wait for k3s to be ready
echo "Waiting for k3s to be ready..."
sudo k3s kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Get node token for workers
echo "k3s master installation complete!"
echo "Node token location: /var/lib/rancher/k3s/server/node-token"
echo "Master IP will be needed for worker nodes"

# Display cluster info
echo "Cluster status:"
sudo k3s kubectl get nodes
sudo k3s kubectl cluster-info

echo "To get the node token for workers, run:"
echo "sudo cat /var/lib/rancher/k3s/server/node-token"