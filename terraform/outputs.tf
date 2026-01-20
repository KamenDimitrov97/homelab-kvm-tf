output "storage1_nfs_volume_name" {
  value = libvirt_volume.storage1_nfs.name
}

output "storage1_nfs_capacity_gb" {
  value = libvirt_volume.storage1_nfs.capacity / local.gib
}

