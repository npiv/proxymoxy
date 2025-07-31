#!/bin/bash
set -e

# Configuration - Update these variables
MASTER_IP="<MASTER_IP>"
NODE_TOKEN="<NODE_TOKEN>"

echo "Starting k3s worker node join process..."

# Validate required variables
if [ "$MASTER_IP" = "<MASTER_IP>" ] || [ "$NODE_TOKEN" = "<NODE_TOKEN>" ]; then
    echo "Error: Please update MASTER_IP and NODE_TOKEN variables in this script"
    echo "Get the master IP from Terraform output or VM console"
    echo "Get the node token by running: sudo cat /var/lib/rancher/k3s/server/node-token on master"
    exit 1
fi

# Update system packages
sudo apt update && sudo apt upgrade -y

# Install k3s agent (worker node)
echo "Joining k3s cluster with master at $MASTER_IP..."
curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$NODE_TOKEN sh -

# Wait for node to be ready
echo "Waiting for node to join cluster..."
sleep 30

echo "Worker node join complete!"
echo "Verify the node joined by running on master:"
echo "sudo k3s kubectl get nodes"