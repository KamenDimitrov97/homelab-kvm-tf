# Phase 4 — Shared Storage Setup (NFS) (Declarative)

## Purpose of this phase

Set up **shared storage** for your Kubernetes workers using **NFS on `storage1`**, tf and ansible.

---

## Key design decisions (and why)

### 1) Storage separation model

| Layer | What it stores | Why |
|---|---|---|
| Host storage | ISOs, VM images, Terraform/Ansible artifacts, backups | Infra lifecycle ≠ app lifecycle |
| `storage1` (NFS) | App data for Kubernetes (future PV/PVC) | Cluster-scoped shared storage (RWX) |
| VM root disks | OS + Kubernetes components | Node-specific, disposable |

---

### 2) Why NFS now (RWX)

Kubernetes access modes:
- **RWO** — one node
- **RWX** — many nodes at once

NFS provides **RWX** with minimal complexity and good learning value.

**Deliberate choice:** keep it simple now; evolve to Longhorn/Ceph to handle high availability(HA).

---

### 3) Failure model: accepted SPOF for now

`storage1` is a **single point of failure** (not HA). If it goes down, NFS-backed workloads are impacted.

**Why we accept this in Phase 4**
- HA storage is its own project
- You want a working cluster first
- Clean architecture beats early complexity

Mitigation later: backups + eventual HA storage.

---

### 4) Control planes do not mount NFS

Only **workers** mount the NFS share.

**Why**
- Keeps control planes minimal and easier to debug
- Most app workloads live on workers

---

### 5) Security: `root_squash`

Use `root_squash` so “root on a client” is not “root on the NFS server”.

**Why**
- Prevents pods (or nodes) acting as root from owning server files
- Safer defaults for Kubernetes-style workloads
- Easier to get right now than later

---

## Declarative ownership: Terraform vs Ansible

### Terraform owns infrastructure objects

- Create `storage1` VM (cpu/ram/network/hostname)
- Attach the 200GB disk as `/dev/vdb`
- manage DNS/DHCP reservations

---

### Ansible owns OS + service state

- Partition/format `/dev/vdb`
- Ensure filesystem is **ext4**
- Mount at `/srv/nfs` and persist in `/etc/fstab`
- Install and configure `nfs-kernel-server`
- Manage `/etc/exports`
- Validate mounts + read/write tests from workers

---

## “Ensure ext4” policy

Your policy: **always ensure ext4 on `/dev/vdb`.**

Implementation behavior should be:

- ✅ If `/dev/vdb` is blank/unformatted → format ext4
- ✅ If `/dev/vdb` is already ext4 → do nothing
- ❌ If `/dev/vdb` is formatted but NOT ext4 → **fail hard**

---

## Inputs we already know (facts)

- `storage1` has an unused disk: **`/dev/vdb` (200G)**
- Workers can reach `storage1` by hostname: **DNS resolution works**
- Firewall (UFW) status is unknown (common to be inactive on Ubuntu)

---

## Architecture overview

```
Host (hypervisor): infra-only storage
  /srv/infra  (optional export for ISOs/backups/artifacts)

storage1: cluster shared storage (NFS)
  /dev/vdb -> /srv/nfs
           -> /srv/nfs/rwx  (exported)

Workers: consume NFS
  w1, w2 mount storage1:/srv/nfs/rwx for validation (and later k8s)
```

---
