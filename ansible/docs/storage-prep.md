# Storage preparation

The role of this playbook is to assert the disks have been created successfully, assert some data about them and then converting one of the disks into a usable persistent storage. 

---
## Responsabilities

- asserting that the expected disks exist
- make sure the data disk has a supported filesystem
- format the disk if required to `ext4`
- mounting the disk at `/srv/nfs`
- persisting the mount via UUID-based `/etc/fstab`

---
## Play definition

```sh
- name: Storage Preparation
  hosts: storage
  become: true
  gather_facts: true
```

- `hosts: storage` Hosts are only the storage hosts, currently `storage1`.
- `become: true` run with root privileges, needed for disk inspection, mounting etc.
- `gather_facts: true` used for inspecting block devices.

---
## Design

This playbook follows a strict separation of concerns:

- Terraform - Handles the creation and attachment of disks
- Ansible - Ensures correct state a.k.a filesystem, mountpoint, persistence.


---
## Tasks

### Gather hardware facts

```yaml
- name: Gather hardware facts
  ansible.builtin.setup:
    gather_subset:
      - hardware
```

- Limits fact gathering to hardware only.
- Make sure ansible_facts.devices are populated

### Assert storage disks exist

```yaml
- name: Assert storage disks exist
  ansible.builtin.assert:
    that:
      - "'vda' in ansible_facts.devices"
      - "'vdb' in ansible_facts.devices"
      - "'vdc' in ansible_facts.devices"
    fail_msg: "One or more storage disks are missing"
```

Self-explanatory, asserts disks `vda`, `vdb` and `vdc` exist.
Essentially testing if terraform did it's job correctly.

### Detect filesystem signature on /dev/vdc

```yaml
- name: Detect filesystem signature on /dev/vdc
  ansible.builtin.command: "blkid -o value -s TYPE /dev/vdc"
  register: vdc_blkid
  changed_when: false
  failed_when: false
```

Essentially equivalent to running this on `storage` hosts:

```sh
blkid -o value -s TYPE /dev/vdc
```
Which will return the filesystem type. (`ext4`)

### Set filesystem fact

```yaml
- name: Set vdc_fs with disk format
  ansible.builtin.set_fact:
    vdc_fs: "{{ vdc_blkid.stdout | default('') | trim }}"
```

Essentially sets the file system type as a fact in disk info.

### Format disk if required

```yaml
- name: Format /dev/vdc as ext4
  ansible.builtin.filesystem:
    fstype: ext4
    dev: /dev/vdc
  when: vdc_fs != 'ext4'
```

Again self-explanatory, but essentially it checks if file extension(or the fact we created earlier) is `ext4`, formats to `ext4` if it's not.

### Get filesystem UUID

```yaml
- name: Get UUID of /dev/vdc
  ansible.builtin.command: blkid -o value -s UUID /dev/vdc
  register: vdc_uuid
  changed_when: false
```

Get the uuid of `/dev/vdc` disk and register a variable housing it.


### Create mountpoint

```yaml
- name: Create mountpoint /srv/nfs
  ansible.builtin.file:
    path: /srv/nfs
    state: directory
    owner: root
    group: root
    mode: '0755'
```

Creates/ensures a valid mountpoint(dir) called `srv/nfs`. 


### Mount disk via UUID

```yaml
- name: Mount /dev/vdc at /srv/nfs via UUID
  ansible.builtin.mount:
    path: /srv/nfs
    src: "UUID={{ vdc_uuid.stdout }}"
    fstype: ext4
    opts: defaults
    state: mounted
```

- Mounts the FS 
- writes an `/etc/fstab` entry to make it persisten
- use UUID rather than device name

### Read /etc/fstab

```yaml
- name: Read /etc/fstab
  ansible.builtin.slurp:
    src: /etc/fstab
  register: fstab_raw
```

We read this file so that we can assert that the UUID is present.

### Assert UUID exists in `/etc/fstab` 

```yaml
- name: Assert UUID exists in /etc/fstab
  ansible.builtin.assert:
    that:
      - "vdc_uuid.stdout in (fstab_raw.content | b64decode)"
    fail_msg: "UUID {{ vdc_uuid.stdout }} not found in /etc/fstab"
```

We make sure the disk has an entry in `/etc/fstab`.

