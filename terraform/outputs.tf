output "master_ip" {
  description = "IP address of the k3s master node"
  value       = var.master_vm.ip
}

output "master_vm_id" {
  description = "VM ID of the k3s master node"
  value       = proxmox_vm_qemu.k3s_master.vmid
}

output "worker_ips" {
  description = "IP addresses of all worker nodes"
  value = {
    for k, v in var.worker_vms : k => v.ip
  }
}

output "worker_vm_ids" {
  description = "VM IDs of all worker nodes"
  value = {
    for k, v in proxmox_vm_qemu.k3s_workers : k => v.vmid
  }
}

output "cluster_nodes" {
  description = "All cluster node information"
  value = {
    master = {
      name = var.master_vm.name
      ip   = var.master_vm.ip
      vmid = proxmox_vm_qemu.k3s_master.vmid
    }
    workers = {
      for k, v in var.worker_vms : k => {
        name = v.name
        ip   = v.ip
        vmid = proxmox_vm_qemu.k3s_workers[k].vmid
      }
    }
  }
}

output "ssh_command_master" {
  description = "SSH command to connect to master node"
  value       = "ssh ${var.vm_user}@${var.master_vm.ip}"
}

output "ssh_commands_workers" {
  description = "SSH commands to connect to worker nodes"
  value = {
    for k, v in var.worker_vms : k => "ssh ${var.vm_user}@${v.ip}"
  }
}