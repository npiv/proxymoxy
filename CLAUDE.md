# Claude Context Notes - Proxmox k3s Homelab Project

## Project Overview
Building a Kubernetes homelab on Proxmox for learning and running media/document management services.

## Hardware Configuration
- **Host**: Proxmox server
- **Current RAM**: 16GB (2x 8GB DDR3-1600 in ChannelA slots)
- **RAM Upgrade**: Timetec DDR3L/DDR3 1600MHz 16GB Kit (arriving tomorrow)
- **Final RAM**: 32GB total (4x 8GB, all slots filled)
- **Storage**: 
  - 500GB SSD (Proxmox host + VM disks)
  - 4TB HDD (already mounted with existing data, used for media/documents)

## Architecture Decisions Made
- **3-worker setup** chosen for Kubernetes learning (vs 2-worker for efficiency)
- **32GB RAM allocation**: 4GB host reserve, 4GB master, 8GB per worker
- **Storage strategy**: SSD for OS/containers, HDD for bulk data
- **Deployment stack**: Terraform + Bash scripts + ArgoCD (no Ansible)

## Services to Deploy
- **Media Stack**: Plex (worker-1), Sonarr/Radarr/Bazarr/Prowlarr (worker-2)
- **Documents**: Paperless-ngx (worker-3)  
- **Downloads**: qBittorrent (worker-3)
- **Infrastructure**: Traefik ingress, cert-manager, monitoring

## Key Files
- `PLAN.md`: Complete implementation plan with phases
- Infrastructure will be in terraform/, scripts/, argocd/, k8s-manifests/ directories

## Current Status
- Planning phase completed
- RAM upgrade ordered (Timetec DDR3L 16GB kit)
- Ready to begin Phase 1 (Infrastructure as Code setup) after RAM installation

## Important Context
- User prioritizes learning Kubernetes concepts over pure efficiency
- Existing 4TB HDD has data, so need to mount not format
- Using GitOps approach with ArgoCD for application management
- Focus on professional, reproducible infrastructure patterns