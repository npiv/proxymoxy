variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_user" {
  description = "Proxmox username"
  type        = string
}

variable "proxmox_password" {
  description = "Proxmox password"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
}

variable "vm_template" {
  description = "VM template name"
  type        = string
  default     = "ubuntu-24.04-cloudinit"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "vm_user" {
  description = "Default user for VMs"
  type        = string
  default     = "ubuntu"
}

variable "network_bridge" {
  description = "Network bridge for VMs"
  type        = string
  default     = "vmbr0"
}

variable "storage_pool" {
  description = "Storage pool for VM disks"
  type        = string
  default     = "local-lvm"
}

variable "hdd_storage_path" {
  description = "Path to HDD storage mount on Proxmox host"
  type        = string
  default     = "/mnt/hdd-data"
}

variable "master_vm" {
  description = "Master node configuration"
  type = object({
    name      = string
    cores     = number
    memory    = number
    disk_size = string
    ip        = string
  })
  default = {
    name      = "k3s-master"
    cores     = 2
    memory    = 4096
    disk_size = "32G"
    ip        = "192.168.1.120"
  }
}

variable "worker_vms" {
  description = "Worker nodes configuration"
  type = map(object({
    name      = string
    cores     = number
    memory    = number
    disk_size = string
    ip        = string
  }))
  default = {
    worker1 = {
      name      = "k3s-worker-1"
      cores     = 4
      memory    = 8192
      disk_size = "32G"
      ip        = "192.168.1.121"
    }
    worker2 = {
      name      = "k3s-worker-2"
      cores     = 3
      memory    = 8192
      disk_size = "32G"
      ip        = "192.168.1.122"
    }
    worker3 = {
      name      = "k3s-worker-3"
      cores     = 3
      memory    = 8192
      disk_size = "32G"
      ip        = "192.168.1.123"
    }
  }
}

variable "gateway" {
  description = "Network gateway"
  type        = string
  default     = "192.168.128.1"
}

variable "dns_servers" {
  description = "DNS servers"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}