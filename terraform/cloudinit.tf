resource "libvirt_cloudinit_disk" "seed" {
  for_each = local.nodes

  name = "${each.key}-seed.iso"

  user_data = templatefile("${path.module}/cloudinit/user-data.yaml.tftpl", {
    username = "stroming"
    keys     = local.ssh_keys
  })

  meta_data = templatefile("${path.module}/cloudinit/meta-data.yaml.tftpl", {
    hostname = each.key
  })
}
# Upload the generated ISO into your libvirt pool
resource "libvirt_volume" "seed" {
  for_each = local.nodes

  name   = "${each.key}-seed"
  pool   = "vmpool"
  format = "iso"

  create = {
    content = {
      url = libvirt_cloudinit_disk.seed[each.key].path
    }
  }
}
