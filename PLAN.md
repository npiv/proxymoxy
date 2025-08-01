# Proxmox k3s Homelab Setup Plan

## Hardware Overview
- **Host**: Proxmox with 32GB RAM (16GB existing + 16GB upgrade), 8GB swap
- **Storage**: 500GB SSD (Proxmox + VMs) + 4TB HDD (media/documents, pre-existing data)
- **RAM Upgrade**: Timetec DDR3L/DDR3 1600MHz 16GB Kit arriving tomorrow

## Virtual Machine Architecture (3-Node Learning Setup)

### Resource Allocation (Post-RAM Upgrade)
```
Proxmox Host (32GB RAM total)
├── Host OS Reserve: ~4GB
├── k3s-master: 4GB RAM, 2 CPU, 32GB disk (SSD)
├── k3s-worker-1: 8GB RAM, 4 CPU, 32GB disk (SSD)
├── k3s-worker-2: 8GB RAM, 3 CPU, 32GB disk (SSD)
└── k3s-worker-3: 8GB RAM, 3 CPU, 32GB disk (SSD)
```

**Total VM allocation: 28GB RAM (4GB host buffer)**

### Performance Benefits (32GB Setup)
- **Generous Resources**: Each worker gets 8GB RAM for comfortable operation
- **Transcoding Headroom**: Plex can handle multiple simultaneous streams
- **Concurrent Operations**: Multiple arr services can run heavy operations simultaneously
- **Development Space**: Room for additional services and experimentation

### Learning Benefits
- **High Availability**: Experience true k8s HA with quorum behavior
- **Pod Scheduling**: Practice node affinity, taints, and tolerations
- **Resource Management**: Learn resource requests/limits in realistic scenarios
- **Failure Scenarios**: Simulate node failures and recovery procedures

## Storage Strategy

### SSD (500GB) - Fast Storage
- Proxmox host OS
- VM root filesystems
- Container images and layers
- Application databases
- k3s etcd data

### HDD (4TB) - Bulk Storage
- Media files (movies, TV, music)
- Paperless document storage
- Download directories
- Configuration backups

### Mount Structure
```
/mnt/hdd-data/
├── media/
│   ├── movies/
│   ├── tv/
│   └── music/
├── downloads/
├── paperless/
│   ├── documents/
│   ├── consume/
│   └── export/
├── config/
│   └── backups/
└── arr-data/
```

## k3s Cluster Services

### Infrastructure Layer
- **k3s**: Lightweight Kubernetes distribution
- **Traefik**: Ingress controller (reverse proxy)
- **Cert-Manager**: Automatic SSL certificate management
- **Local-Path Provisioner**: Dynamic storage provisioning

### Media Management Stack
- **Plex Media Server**: Media streaming (worker-1)
- **Sonarr**: TV show management
- **Radarr**: Movie management  
- **Bazarr**: Subtitle management
- **Prowlarr**: Indexer manager
- **qBittorrent**: Torrent client

### Document Management
- **Paperless-ngx**: Document digitization and management

### Service Distribution Strategy
- **k3s-master**: Control plane only (no workloads for learning purposes)
- **k3s-worker-1**: Plex Media Server (highest resource requirements for transcoding)
- **k3s-worker-2**: Arr suite (Sonarr, Radarr, Prowlarr, Bazarr)
- **k3s-worker-3**: Paperless-ngx, qBittorrent, monitoring tools

### Kubernetes Learning Opportunities
- **Node Affinity**: Pin Plex to worker-1 for consistent performance
- **Resource Limits**: Set CPU/memory limits to prevent resource starvation
- **Pod Anti-Affinity**: Spread arr services across multiple nodes
- **Taints/Tolerations**: Reserve master node for control plane only
- **Persistent Volumes**: Manage storage across multiple nodes

## Network Architecture
- Internal cluster networking (flannel CNI)
- External access via Traefik reverse proxy
- SSL certificates for all services
- Subdomain routing (plex.domain.com, sonarr.domain.com, etc.)

## Deployment Strategy

### Infrastructure as Code Stack
```
ArgoCD
├── GitOps application deployment
├── Helm chart management
├── Continuous deployment
└── Configuration drift detection
```

### Repository Structure
```
proxmox-k3s/
├── argocd/
│   ├── applications/
│   ├── projects/
│   └── repositories/
└── k8s-manifests/
    ├── plex/
    ├── arr-suite/
    ├── paperless/
    └── infrastructure/
```

## Implementation Phases

### Phase 1: Infrastructure as Code Setup
1. Install RAM upgrade and configure Proxmox host
2. Set up machines
3. Create VM definitions with proper resource allocation
4. Configure cloud-init templates for Ubuntu Server
5. Provision all VMs with shared HDD storage mounts

### Phase 2: k3s Cluster Bootstrap
1. Create bash scripts for k3s installation
2. SSH to master node and install k3s
3. Extract join token and configure worker scripts
4. Join all worker nodes to cluster
5. Configure kubectl access and validate cluster health

### Phase 3: GitOps Foundation
1. Deploy ArgoCD to k3s cluster
2. Set up Git repository with k8s manifests
3. Configure ArgoCD projects and applications
4. Test GitOps workflow with simple deployment

### Phase 4: Storage and Networking
1. Configure local-path storage class with HDD mounts
2. Deploy Traefik ingress controller via ArgoCD
3. Set up cert-manager for automatic SSL certificates
4. Configure DNS and ingress rules

### Phase 5: Application Deployment via GitOps
1. Deploy Plex with node affinity to worker-1
2. Deploy arr suite (Sonarr, Radarr, Prowlarr, Bazarr) to worker-2
3. Deploy Paperless-ngx and qBittorrent to worker-3
4. Configure persistent storage and service integrations

### Phase 6: Monitoring and Optimization
1. Deploy monitoring stack (Prometheus, Grafana)
2. Set up backup strategies for configurations
3. Implement resource monitoring and alerting
4. Performance tuning and optimization

## Success Criteria
- [ ] All VMs running with proper resource allocation
- [ ] k3s cluster healthy with all nodes joined
- [ ] All services accessible via HTTPS subdomains
- [ ] Media files accessible to Plex from HDD storage
- [ ] Arr suite configured and downloading to HDD
- [ ] Paperless-ngx processing documents from HDD
- [ ] Automatic SSL certificate renewal working
- [ ] Basic backup strategy implemented
