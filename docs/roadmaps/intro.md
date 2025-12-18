# Homelab Kubernetes Roadmap (KVM/libvirt + kubeadm + Ubuntu)

## Phase 0 — Design locked
- Topology: **3 control-planes + 2 workers**
- Host: **Ubuntu Server (bare metal) + KVM/libvirt**
- Networking: **bridged LAN (br0)** + **DHCP reservations**
- Storage:
  - Per-node VM disks (OS + node-local data as needed)
  - **Host NFS** for infra/hypervisor needs
  - **Storage VM** (`storage1`) with **200GB disk** exporting **NFS** for Kubernetes shared volumes
- Provisioning: **Terraform** for VMs (libvirt) + cloud-init
- Cluster bootstrap: **kubeadm**
- Traffic: **Gateway API** (implementation chosen later)

---

## Phase 1 — Build the hypervisor host
1. Install **Ubuntu Server LTS** on bare metal ✅
   1. Make server reachable over the internet, possibly using tailscale
2. Enable virtualization in BIOS/UEFI (**VT-x**; **VT-d/IOMMU** optional) ✅
3. Install KVM stack (qemu-kvm, libvirt, virt tools) ✅
4. Create **br0** bridge so host + VMs are on your LAN ✅
5. Create a libvirt **storage pool** on the NVMe (where VM disks live) 

**Deliverable:** host is stable, reachable over LAN and the internet, ready to spawn VMs.✅

---

## Phase 2 — Terraform the VM fleet
1. Create Terraform project structure (providers/vars/outputs)✅
2. Define nodes as data (maps): `cp1-3`, `w1-2`, `storage1`✅
3. Use Ubuntu cloud image + cloud-init:✅
   - user + SSH key✅
   - hostname✅
4. Create disks:✅
   - OS disks per VM✅
   - `storage1` extra disk = **200GB**✅
5. Attach NICs to `br0`✅
6. Output VM **MAC addresses** (for router DHCP reservations)✅

**Deliverable:** `terraform apply` creates all VMs and prints MACs.✅

---

## Phase 3 — IPs + basic node readiness
1. Configure DHCP reservations on router for:
   - `cp1 cp2 cp3 w1 w2 storage1`
2. Verify:
   - all VMs reachable via SSH
   - all nodes can reach each other (temporary `/etc/hosts` is fine)
   - time sync is working (chrony/systemd-timesyncd)

**Deliverable:** clean connectivity + stable addressing.

---

## Phase 4 — Shared storage setup (NFS)
1. **Host NFS export** (infra use)
   - export a directory for ISOs/backups/artifacts (NOT Kubernetes PVs)
2. **storage1 NFS server**
   - format + mount the 200GB disk
   - export via NFS
3. Validate from a worker:
   - mount NFS share
   - basic read/write tests

**Deliverable:** working NFS from `storage1` for Kubernetes RWX volumes later.

---

## Phase 5 — kubeadm cluster bootstrap (base Kubernetes)
1. On all k8s nodes (control-planes + workers):
   - disable swap, load kernel modules, set sysctl
   - install containerd
   - install kubeadm/kubelet/kubectl
2. Initialize cluster on `cp1`
3. Join `cp2` and `cp3` as additional control-planes
4. Join `w1` and `w2`
5. Install CNI (Calico or Cilium — decide when you get here)
6. Verify nodes Ready + core system pods healthy

**Deliverable:** functioning multi-control-plane cluster.

---

## Phase 6 — Platform basics (infra-focused)
1. Install **MetalLB** (LoadBalancer services on your LAN)
2. Pick and install a **Gateway API implementation**
3. Deploy a demo app exposed via Gateway

**Deliverable:** LAN-reachable services with modern Gateway routing.

---

## Phase 7 — GitOps bootstrap
1. Install **Argo CD** or **Flux**
2. Define repo structure:
   - `platform/` (MetalLB, Gateway, storage class, cert-manager later)
   - `apps/` (demo workloads)
3. Make the cluster self-managing from Git

**Deliverable:** cluster state driven from Git.

---

## Phase 8 — Kubernetes storage (NFS-backed RWX)
1. Install an NFS CSI / provisioner (or external provisioner)
2. Create a StorageClass for `storage1` NFS
3. Deploy apps using RWX PVCs
4. Practice backup/restore of PV data

**Deliverable:** shared RWX storage working in-cluster.

---

## Phase 9 — Monitoring (later)
1. metrics-server
2. Prometheus + Grafana (kube-prometheus-stack)
3. Alerts + dashboards
4. Watch resource pressure and tune VM sizing if needed

**Deliverable:** observability baseline.

---

## Phase 10 — Ops drills (level-up)
- Node drain/cordon + safe maintenance
- Control-plane failure simulation (stop `cp2`, verify cluster still works)
- etcd snapshot/restore practice
- Kubernetes version upgrades (kubeadm upgrade flow)
- Disaster rebuild: destroy VMs, `terraform apply`, restore GitOps state

**Deliverable:** confidence operating + recovering the cluster.

