locals {
  gib = 1024 * 1024 * 1024 # Gigabyte = b * kb * mb

  nodes = {
    cp1 = { vcpu = 2, ram_mb = 4096, root_gb = 30, data_gb = 50, mac = "52:54:00:00:00:11" }
    cp2 = { vcpu = 2, ram_mb = 4096, root_gb = 30, data_gb = 50, mac = "52:54:00:00:00:12" }
    cp3 = { vcpu = 2, ram_mb = 4096, root_gb = 30, data_gb = 50, mac = "52:54:00:00:00:13" }
    w1  = { vcpu = 2, ram_mb = 6144, root_gb = 30, data_gb = 100, mac = "52:54:00:00:00:21" }
    w2  = { vcpu = 2, ram_mb = 6144, root_gb = 30, data_gb = 100, mac = "52:54:00:00:00:22" }

    storage1 = { vcpu = 1, ram_mb = 2048, root_gb = 20, data_gb = 30, mac = "52:54:00:00:00:31" }
  }

  ssh_keys = split("\n", trimspace(file("${path.module}/ssh/authorized_keys.pub")))
}
