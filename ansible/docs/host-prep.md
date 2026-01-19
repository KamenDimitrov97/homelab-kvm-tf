# Host preparation – libvirt hypervisor

This playbook prepares the **hypervisor host**. The machine that will host all of the virtual machines.

It is responsible for:
- installing the virtualization stack
- enabling required services
- configuring host networking which includes bridge `br0`

This playbook is intentionally **host-only**.  
It does **not** create VMs and does **not** configure anything inside VMs.

---

## Play definition

```yaml
- name: Host preparation
  hosts: hypervisor
  become: true
  gather_facts: true
```

- `hosts: hypervisor`  
  Targets hosts added under inventory.ini [hypervisor], which is the localhost.

- `become: true`  
  All tasks require root privileges (package install, services, `/etc/netplan`).

- `gather_facts: true`  
  Gathers host information.

---

## Variables

These variables define **what packages get installed** and **what services should be running**.

```yaml
vars:
  host_prep_packages:
    # virtualization stack
    - qemu-kvm
    - libvirt-daemon-system
    - libvirt-clients
    - virtinst
    - apparmor
    - apparmor-utils
    - bridge-utils
    - cloud-image-utils

  host_prep_services:
    - libvirtd
    - virtlogd
    - apparmor
```

## Tasks

### Update apt cache

```yaml
- name: Update apt cache
  ansible.builtin.apt:
    update_cache: true
    cache_valid_time: 3600 # 1h
```

Equivalent to:

```bash
sudo apt-get update
```

- Refreshes package metadata

---

### Install required packages

```yaml
- name: Install required packages
  ansible.builtin.apt:
    name: "{{ host_prep_packages }}"
    state: present
```

- Installs everything listed in `host_prep_packages`
- Idempotent: packages already installed are skipped

---

### Ensure services are enabled and started

```yaml
- name: Ensure services are enabled and started
  ansible.builtin.systemd:
    name: "{{ item }}"
    enabled: true
    state: started
  loop: "{{ host_prep_services }}"
```

For each service in `host_prep_services`:
- ensures it starts on boot
- ensures it is currently running

This avoids relying on implicit package defaults.

---

### Sanity check – service status

```yaml
- name: Sanity check - show service status (quick)
  ansible.builtin.command: "systemctl is-active {{ item }}"
  changed_when: false
  loop: "{{ host_prep_services }}"
```

- Verifies that each service is actually active
- Useful for troubleshooting

---

## Network safety check

Before touching host networking, we validate that the uplink NIC exists.
This is why we need `gather_facts: true`. 
```yaml
- name: Assert uplink NIC exists
  ansible.builtin.assert:
    that:
      - bridge_uplink_nic in ansible_facts.interfaces
    fail_msg: "NIC {{ bridge_uplink_nic }} not found on host"
```

### Why this exists

- Enslaving the wrong NIC into a bridge can **cut off networking**
- If this playbook is run remotely, that would lock you out

---

## Netplan bridge configuration

### Installing the netplan configuration

```yaml
- name: Install br0 netplan
  ansible.builtin.template:
    src: 01-br0.yaml.j2
    dest: /etc/netplan/01-br0.yaml
    owner: root
    group: root
    mode: "0644"
  notify: netplan apply
```

What this does:
- Renders the Netplan configuration from a Jinja2 template
- Writes it to `/etc/netplan/01-br0.yaml`
- Does **not** apply the change immediately

The task **notifies a handler** only if the file content actually changes.

---

## Handler: applying the network change

```yaml
handlers:
  - name: netplan apply
    ansible.builtin.command: netplan apply
```

### What a handler is

A handler:
- runs only if notified
- runs once, even if notified multiple times
- runs at the end of the play

In this case, networking is only applied **if the config changed**.

---

### Why `netplan apply` is used

`netplan apply`:
- applies the new network configuration

I was contemplating using netplan try --timeout, but that has requirements I'm not aware of.

---

## Summary

This playbook:
- prepares the hypervisor host in a repeatable way
- installs and validates the kvm irtualization stack
- configures host networking safely
- separates **rendering configuration** from **applying changes**

It is intentionally conservative and explicit, because **breaking the hypervisor breaks everything.**
