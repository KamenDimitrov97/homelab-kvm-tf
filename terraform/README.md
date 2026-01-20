# Homelab – Terraform + Ansible

This repository defines and operates a **local homelab virtualization environment**
built on **libvirt/KVM**.

It is intentionally split into two layers:

- **Terraform (root directory)** → builds infrastructure
- **Ansible (`ansible/`)** → prepares the host and validates node readiness

Terraform creates vms.  
Ansible configures and asserts state.

---

## High-level overview

- Bare‑metal hypervisor running libvirt/KVM
- Bridged networking (`br0`) to the LAN
- Terraform creates virtual machines
- Ansible prepares the host and validates nodes
- Manual DHCP reservations from router

---

## Repository layout

```text
homelab-tf/
├── README.md
├── Makefile               # VM power operations (virsh)
├── providers.tf
├── locals.tf
├── vms.tf
├── cloudinit.tf
├── cloudinit/
├── ssh/
├── ansible/
│   ├── README.md
│   ├── Makefile
│   ├── inventory.ini
│   ├── host-prep.yaml
│   ├── node-readiness.yaml
│   └── docs/
│       ├── host-prep.md
│       ├── node-readiness.md
│       └── changes.md
└── terraform.tfstate*
```

---

## Responsibilities

### Terraform (root)

Handles **VM lifecycle only**:

- Define libvirt domains
- Attach disks and networks
- Wire cloud-init

---

### Ansible (`ansible/`)

Handles **host prep and safety checks**:

- Hypervisor preparation (packages, services, bridge)
- SSH reachability checks
- Static hostname resolution
- Time synchronization
- Node-to-node connectivity validation

Docs:
- `ansible/docs/host-prep.md`
- `ansible/docs/node-readiness.md`
- `ansible/README.md`

---

## Required manual setup

### DHCP reservations (mandatory)

Static DHCP reservations must be configured on the router.

Example:

| Hostname | IP |
|---------|----|
| cp1 | 192.168.31.11 |
| cp2 | 192.168.31.12 |
| cp3 | 192.168.31.13 |
| w1  | 192.168.31.14 |
| w2  | 192.168.31.15 |
| storage1 | 192.168.31.16 |

Ansible assumes these are correct and fails fast if not.

---

## Typical workflow

### 1) Prepare hypervisor

```bash
cd ansible
## root/ansible
make host-prep
```

---

### 2) Create VMs

```bash
## root/
terraform init
terraform apply
```

---

### 3) Validate readiness

```bash
cd ansible
## root/ansible
make node-readiness
```

If this fails, stop.

---

### 4) Operate VMs

```bash
## root/
make up
make down
make reboot
make status
```

---

### Generic scripts

Run `make help` to view available cmds.

## Notes

- Local Terraform state
- Single hypervisor assumption
- Bridged networking (no NAT)

### NAT networking

With NAT, VMs are hidden behind the hypervisor and are not clean LAN members.
I wanted to make this as close to hooking up physical machines as possible. 
Another goal of not using NAT was to make sure that setting up kubernetes isn't painful from a networking perspective (since I'm still developing networking skills).
In the future I will research the benefits and drawbacks of NAT and see if I can incorporate it. For now I've found out that it may cause some [k8s setting up issues.](#why-nat-can-break-some-kubernetes-setups)

---
