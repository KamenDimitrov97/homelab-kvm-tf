# Node readiness – VM sanity checks

This playbook validates **basic assumptions after Terraform VM creation**.
It does **not** configure applications or Kubernetes; it only verifies that the
infrastructure is sane and usable. 🧪

---

## Purpose

This playbook asserts that:

- all VMs received their expected DHCP leases
- SSH is reachable on all nodes
- hostname resolution is consistent across nodes
- system clocks are synchronized (required for Kubernetes / etcd)
- nodes can reach each other by hostname

If this playbook fails, higher‑level automation **must not proceed**.

---

## Play definition

```yaml
- name: IPs, basic node readiness
  hosts: all
  become: true
```

- Runs on **all VMs**
- Uses superuser privileges because it touches `/etc/hosts` and system services

---

## Task: Ensure SSH is reachable

```yaml
- name: Ensure SSH is reachable
  wait_for:
    host: "{{ ansible_host }}"
    port: 22
    timeout: 20
  delegate_to: localhost
  become: false
```

### What this does

- For each VM, waits up to **20 seconds** for TCP port **22** to be reachable
- Uses `ansible_host` from `inventory.ini`
- Runs from **localhost**, not from another VM

### Why this exists

- Ensures DHCP reservations were applied correctly
- Ensures networking is up before proceeding
- Fails fast if a VM is unreachable

---

## Task: Install `/etc/hosts` from inventory

```yaml
- name: Install /etc/hosts from inventory
  template:
    src: templates/hosts.j2
    dest: /etc/hosts
    mode: "0644"
```

### What this does

- Renders a hosts file using `templates/hosts.j2`
- Populates `/etc/hosts` with **all VMs and hostnames**
- Ensures consistent name resolution without relying on external DNS

### Why this exists

- Kubernetes components rely heavily on hostname resolution
- Avoids subtle DNS issues during early cluster bootstrapping
- Makes node‑to‑node checks deterministic

---

## Task: Ensure time sync service is enabled

```yaml
- name: Ensure time sync service is enabled
  service:
    name: systemd-timesyncd
    enabled: true
    state: started
```

### What this does

- Enables and starts `systemd-timesyncd`
- Ensures the service survives reboots

### Why this exists

- Clock drift breaks **etcd**, TLS, and controller coordination
- Kubernetes assumes reasonably synchronized clocks
- NTP is infrastructure hygiene, not an application concern ⏱️

---

## Task: Assert NTP synchronized

```yaml
- name: Assert NTP synchronized
  command: timedatectl show -p NTPSynchronized --value
  register: ntp
  changed_when: false
  failed_when: ntp.stdout.strip() != "yes"
```

### What this does

- Queries the system clock sync status
- Fails the play if the node is **not synchronized**

### Why this exists

- Ensures time sync is not just running, but **effective**
- Requires outbound internet access
- Prevents subtle distributed‑system failures later

---

## Node‑to‑node connectivity check

```yaml
- name: Node-to-node connectivity check (by hostname)
  hosts: cp1
  become: true
```

This play runs only on **cp1** and validates **east‑west connectivity**.

---

### Task: Ping all nodes by hostname

```yaml
- name: Ping all nodes by hostname
  command: "ping -c 1 -W 1 {{ item }}"
  loop: "{{ groups['all'] }}"
  changed_when: false
```

### What this does

- From `cp1`, pings every node by **hostname only**
- Validates:
  - `/etc/hosts` correctness
  - basic L3 connectivity
  - ICMP reachability between nodes

### Why this exists

- Confirms the cluster network is internally consistent
- Avoids surprises when Kubernetes components start talking to each other 🔗

---

## SSH authentication note

During these checks, Ansible may open many SSH connections.
Typing passwords repeatedly is error‑prone and annoying.

Recommended setup:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
```

This:
- starts an SSH agent
- loads your private key once
- allows Ansible to authenticate non‑interactively

This keeps the playbook clean and repeatable.

---

## Summary

This playbook:

- validates DHCP and basic reachability
- enforces consistent hostname resolution
- ensures time synchronization
- confirms node‑to‑node connectivity

It is intentionally **strict** and **pre‑flight oriented**.

If this fails:
> the infrastructure is not ready — and higher layers should not run 🚫

