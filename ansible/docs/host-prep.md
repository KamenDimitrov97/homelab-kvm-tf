# Intro

The whole purpose of this file is to make sure the KVM stack is installed, started and it's services are successfully running on the host machine.
As stated, we are preparing the host machine. Libvirt_hosts include only the local host.

```yaml
- name: Host preparation
  hosts: hypervisor
  become: true # use sudo
```

## Variables
Here've added the packages required. The whole vm stack and the services that run from these packages for further use.
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

Most are self-explanitory.

In this task we update the apt packages metadata. Equivalent to `sudo apt-get update`
```yaml
- name: Update apt cache
  ansible.builtin.apt:        # use the ansible APT module
    update_cache: true        # run `sudo apt-get update`
    cache_valid_time: 3600    # if cache is older than 1h
```

In this task we install the required packages which were in [host_prep_packages](#variables) list.
```yaml
- name: Install required packages
  ansible.builtin.apt:                    # use the ansible APT module
    name: "{{ host_prep_packages }}"      # loop through all packages in host_prep_packages
    state: present                        # package must be present, if not install it
```

In this task we ensure that the [host_prep_services](#variables) that come from the kvm stack are enabled and started.
```yaml
- name: Ensure services are enabled and started
  ansible.builtin.systemd:                  # use the ansible APT module
    name: "{{ item }}"                      # specific service name e.g. libvirtd
    enabled: true                           # must be enabled, if not enable it 
    state: started                          # state must be started, if not start it
  loop: "{{ host_prep_services }}"          # loop through all services in host_prep_services
```

TThis task makes sure they're running successfully.
```yaml
- name: show service status
  ansible.builtin.command: "systemctl is-active {{ item }}"
  changed_when: false
  loop: "{{ host_prep_services }}"
```
