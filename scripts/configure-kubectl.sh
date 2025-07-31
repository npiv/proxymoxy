#!/bin/bash
set -e

MASTER_IP="<MASTER_IP>"

echo "Configuring kubectl access to k3s cluster..."

# Validate required variables
if [ "$MASTER_IP" = "<MASTER_IP>" ]; then
    echo "Error: Please update MASTER_IP variable in this script"
    echo "Get the master IP from Terraform output or VM console"
    exit 1
fi

# Create .kube directory
mkdir -p ~/.kube

# Copy k3s config from master node
echo "Copying kubeconfig from master node..."
scp ubuntu@$MASTER_IP:/etc/rancher/k3s/k3s.yaml ~/.kube/config

# Update server address in kubeconfig
sed -i "s/127.0.0.1/$MASTER_IP/g" ~/.kube/config

# Set proper permissions
chmod 600 ~/.kube/config

echo "kubectl configuration complete!"
echo "Testing cluster access..."
kubectl get nodes
kubectl cluster-info

echo ""
echo "You can now use kubectl to manage your k3s cluster"