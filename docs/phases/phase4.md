# Phase 4 — Shared Storage Setup (NFS)

## Purpose of this phase

The goal of **Phase 4** is to introduce **cluster-level shared storage** in a way that:

- storage can be used by kubernetes,
- keeps infrastructure concerns separated from application data,
- stays simple enough to reason about and debug,
- does not block future improvements.

---

## Design principles

### 1. Separation of concerns

We intentionally separate storage into **three layers**:

| Layer | What it stores | Why |
|----|----|----|
| Host storage | ISOs, VM images, Terraform/Ansible artifacts, backups | Infra lifecycle ≠ app lifecycle |
| `storage1` (NFS) | Application data (future PV/PVC) | Cluster-scoped, RWX capable |
| VM root disks | OS + kube components | Disposable, node-specific |

**Why this matters**  
Kubernetes workloads must not depend on the hypervisor. If the host changes, apps should survive. This mirrors real-world cluster design.

---

### 2. Why NFS (for now)

Kubernetes storage access modes:
- **RWO** – ReadWriteOnce (single node)
- **RWX** – ReadWriteMany (multiple nodes)

Most real applications need **RWX** (shared uploads, media, artifacts, etc.).

**NFS provides RWX natively** with:
- minimal setup,
- predictable behavior,
- excellent learning value.

start with NFS, evolve later.

---

### 3. Failure model (explicitly accepted)

`storage1` is a **single point of failure**.

If it goes down:
- pods block on I/O,
- volumes become unavailable.

This is **acceptable at this stage**.

**Why**:
- HA storage is a project of its own,
- it should not block cluster bootstrapping,
- design cleanliness matters more than HA right now.

Mitigations (future phases):
- backups to host storage,
- snapshots,
- migration to distributed storage.

---

## Phase tasks

```
Phase 4
├── A. Prepare storage1 disk
├── B. Configure NFS server
├── C. Validate from workers
├── D. (Optional) Host infra NFS
└── E. Prepare for Kubernetes usage
```

---

## A. Prepare `storage1` disk

### Context

`storage1` has a dedicated **200GB disk** (`/dev/vdb`) that is currently unused.

### Tasks

1. Partition `/dev/vdb`
2. Format as `ext4`
3. Mount at `/srv/nfs`
4. Persist mount in `/etc/fstab`

### Directory structure

```
/srv/nfs
├── rwx        # Kubernetes RWX volumes
├── backups    # optional
└── shared     # optional
```

Only `/srv/nfs/rwx` will be exported to Kubernetes.

---

## B. Configure NFS server (`storage1`)

### Packages

- `nfs-kernel-server`

### Export scope

Only export what is needed:

```
/srv/nfs/rwx
```

### Access model

- **Clients**: workers only (`w1`, `w2`)
- **Auth**: hostname-based (DNS already works)
- **Security**: `root_squash` enabled

### Why `root_squash`

- root inside pods maps to an unprivileged user,
- permissions stay controlled on the server.
- this prevents security and cleanup problems.
- a pod running as root could own files on the server,

---

## C. Worker-side validation (critical step)

Before Kubernetes ever touches this storage, it must work at the OS level.

### Tasks (on a worker)

1. Mount `storage1:/srv/nfs/rwx` at `/mnt/nfs-test`
2. Create files
3. Write data
4. Delete data
5. Unmount and remount

### Success criteria

- No permission errors
- Files persist across remounts
- Same data visible from another worker

**Why this matters**  
If NFS fails here, Kubernetes will fail later — but with worse error messages and more layers involved.

---

## D. Host infra NFS

### Purpose

- ISOs
- VM images
- Terraform / Ansible artifacts
- Backups

### Rules

- Never mounted inside pods
- Never used for PV/PVC
- Separate export path (e.g. `/srv/infra`)

---

## Completion checklist

- [ ] `/dev/vdb` formatted and mounted on `storage1`
- [ ] `/srv/nfs/rwx` exported via NFS
- [ ] Workers can mount and write
- [ ] Control planes untouched
- [ ] Host infra storage remains separate

---

## Outcome

We now have a **clean, realistic storage foundation**:

- easy to reason about,
- safe to evolve.

