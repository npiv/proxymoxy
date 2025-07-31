# Proxmox k3s Homelab Setup

A complete Infrastructure as Code setup for deploying a 4-node k3s cluster on Proxmox for running media and document management services.

## Prerequisites

- Proxmox server with 32GB RAM installed
- 500GB SSD + 4TB HDD storage configured
- Git and SSH access configured

## Setup Process

Follow these steps in order:

### 1. Infrastructure Deployment

Start with Terraform to provision the VMs:

```bash
cd terraform/
# Follow instructions in terraform/README.md
```

This will create:
- k3s-master (4GB RAM, 2 CPU)
- k3s-worker-1 (8GB RAM, 4 CPU) 
- k3s-worker-2 (8GB RAM, 3 CPU)
- k3s-worker-3 (8GB RAM, 3 CPU)

### 2. k3s Cluster Bootstrap

After VMs are running, bootstrap the k3s cluster:

#### Step 2.1: Install k3s Master

SSH to the master node and run:

```bash
# Copy and run the master installation script
scp scripts/install-k3s-master.sh ubuntu@<master-ip>:~/
ssh ubuntu@<master-ip>
chmod +x install-k3s-master.sh
./install-k3s-master.sh
```

#### Step 2.2: Get Join Token

On the master node, get the token for workers:

```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

#### Step 2.3: Join Worker Nodes

For each worker node:

1. Update `scripts/join-workers.sh` with master IP and token
2. Copy and run on each worker:

```bash
# Update MASTER_IP and NODE_TOKEN in the script first
scp scripts/join-workers.sh ubuntu@<worker-ip>:~/
ssh ubuntu@<worker-ip>
chmod +x join-workers.sh
./join-workers.sh
```

#### Step 2.4: Configure kubectl Access

Set up kubectl on your local machine:

```bash
# Update MASTER_IP in the script first
chmod +x scripts/configure-kubectl.sh
./scripts/configure-kubectl.sh
```

### 3. Verify Cluster

Check that all nodes joined successfully:

```bash
kubectl get nodes
kubectl cluster-info
```

Expected output: 4 nodes (1 master, 3 workers) in Ready state.

## Next Steps

After the cluster is running:

1. **Phase 3**: Deploy ArgoCD for GitOps
2. **Phase 4**: Configure storage and networking (Traefik, cert-manager)
3. **Phase 5**: Deploy applications (Plex, arr suite, Paperless-ngx)
4. **Phase 6**: Implement monitoring and backups

## Architecture

- **Master Node**: Control plane only (no workloads)
- **Worker-1**: Plex Media Server (high CPU for transcoding)
- **Worker-2**: Arr suite (Sonarr, Radarr, Prowlarr, Bazarr)
- **Worker-3**: Paperless-ngx, qBittorrent, monitoring

## Storage Layout

- **SSD (500GB)**: VM root filesystems, container images, databases
- **HDD (4TB)**: Media files, downloads, document storage (mounted to all nodes)

## Troubleshooting

- **VMs not accessible**: Check Proxmox networking and cloud-init logs
- **k3s installation fails**: Verify VM resources and network connectivity
- **Worker join fails**: Confirm master IP, token, and port 6443 accessibility
- **kubectl access issues**: Verify kubeconfig and master node accessibility

For detailed implementation plan, see `PLAN.md`.