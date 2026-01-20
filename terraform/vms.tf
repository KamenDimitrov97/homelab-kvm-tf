# base ubuntu cloud img
resource "libvirt_volume" "ubuntu_base" {
  name   = "ubuntu-24.04-base.qcow2"
  pool   = "vmpool"
  format = "qcow2"
  create = {
    content = {
      url = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"
    }
  }
}

resource "libvirt_volume" "storage1_nfs" {
  name     = "storage1-nfs.qcow2"
  pool     = "vmpool"
  format   = "qcow2"
  capacity = 200 * local.gib
}

resource "libvirt_volume" "root" {
  for_each = local.nodes
  name     = "${each.key}-root.qcow2"
  pool     = "vmpool"
  format   = "qcow2"
  backing_store = {
    path   = libvirt_volume.ubuntu_base.path
    format = "qcow2"
  }
  capacity = each.value.root_gb * local.gib
}

resource "libvirt_volume" "data" {
  for_each = local.nodes

  name     = "${each.key}-data.qcow2"
  pool     = "vmpool"
  format   = "qcow2"
  capacity = each.value.data_gb * local.gib
}

resource "libvirt_domain" "vm" {
  for_each = local.nodes

  name   = each.key
  unit   = "MiB"
  memory = each.value.ram_mb
  vcpu   = each.value.vcpu
  type   = "kvm"

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }
  devices = {
    # NIC on your LAN bridge br0
    interfaces = [
      {
        type  = "bridge"
        mac   = each.value.mac
        model = "virtio"

        # v0.9.0 "flat" source shape
        source = {
          bridge = "br0"
        }
      }
    ]

    # Disks: root + data + cloud-init cdrom
    disks = concat(
      [
        {
          device = "disk"
          target = { dev = "vda", bus = "virtio" }
          driver = { name = "qemu", type = "qcow2" }
          source = {
            pool   = "vmpool"
            volume = libvirt_volume.root[each.key].name
          }
        },
        {
          device = "disk"
          target = { dev = "vdb", bus = "virtio" }
          driver = { name = "qemu", type = "qcow2" }
          source = {
            pool   = "vmpool"
            volume = libvirt_volume.data[each.key].name
          }
        }
      ],
      each.key == "storage1" ? [
        {
          device = "disk"
          target = { dev = "vdc", bus = "virtio" }
          driver = { name = "qemu", type = "qcow2" }
          source = {
            pool   = "vmpool"
            volume = libvirt_volume.storage1_nfs.name
          }
        }
      ] : [],
      [
        {
          device    = "cdrom"
          read_only = true
          target    = { dev = "sda", bus = "sata" }
          driver    = { name = "qemu", type = "raw" }
          source = {
            pool   = "vmpool"
            volume = libvirt_volume.seed[each.key].name
          }
        }
      ]
    )

  }
}

