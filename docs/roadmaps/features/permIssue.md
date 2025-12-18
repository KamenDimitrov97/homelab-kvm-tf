# Homelab Libvirt + AppArmor Declarative Roadmap

## Goal
Run libvirt VMs with qcow2 backing files **without AppArmor breakage**, fully declarative, reproducible, and low-maintenance.

Terraform owns **VM topology**.  
Ansible owns **host OS policy and guarantees**.

---

## Phase 0 – Ground rules
- Never disable AppArmor
- Never hand-edit generated libvirt AppArmor profiles
- Backing files must live in a **stable, whitelisted path**
- No per-VM or per-image AppArmor rules

---

## Phase 1 – Host preparation (Ansible)

### 1.1 Install required packages
- libvirt / qemu
- apparmor + utils
- libvirt client tools

### 1.2 Enable services
- libvirtd
- virtlogd
- apparmor

All enabled + started at boot.

---

### 1.3 Backing image directory (contract)
Create and enforce:

Properties:
- owner: root
- permissions: 0755
- base qcow2 images are **read-only**

This directory is the *only* supported location for backing files.

---

### 1.4 AppArmor local allow rule (core fix)
Add a local AppArmor include (never overwritten by updates):

Allow QEMU to read backing files:

Reload AppArmor declaratively.

Result:
- Any VM may reference backing files here
- No XML hacks
- No profile regeneration loops

---

## Phase 2 – Libvirt pools (Terraform + Ansible contract)

### 2.1 Define two pools
| Pool name | Path | Purpose |
|---------|------|---------|
| basepool | /var/lib/libvirt/base-images | Shared backing images |
| vmpool | /var/lib/libvirt/images | Per-VM overlays |

Ansible ensures paths exist.  
Terraform defines pools pointing at those paths.

---

## Phase 3 – Terraform VM layout

### 3.1 Base image (single download)
- `ubuntu-24.04-base.qcow2`
- Stored in `basepool`
- Never attached to a VM as a disk

### 3.2 VM root disks
- qcow2 overlays in `vmpool`
- `backing_store.path = ubuntu_base.path`

### 3.3 VM data disks
- Independent qcow2 volumes
- No backing file

### 3.4 Domain definition
- Domains reference only overlay volumes
- Backing chain remains transparent to guests

---

## Phase 4 – Execution order (always)

1. **Ansible**
   - Prepare host
   - Enforce AppArmor rules
   - Ensure directories + services

2. **Terraform**
   - Create pools
   - Download base image once
   - Create overlays and domains

---

## Phase 5 – Invariants (what must never change)

- All backing files live under `/var/lib/libvirt/base-images`
- No backing file paths outside that tree
- AppArmor rules only reference directories, never individual files
- Terraform never manages OS security policy

---

## Outcome

✔ Shared base images  
✔ AppArmor stays enabled  
✔ No per-VM hacks  
✔ Fully declarative  
✔ Safe to change VM images in the future  

This design scales from 1 VM to many without policy churn.

