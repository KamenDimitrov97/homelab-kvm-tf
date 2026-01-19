SHELL := /bin/bash

GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
CYAN   := $(shell tput -Txterm setaf 6)
RESET  := $(shell tput -Txterm sgr0)

.PHONY: help check inventory ping facts host-prep host-prep-dry node-readiness lint ssh-agent

check: ## Check if tool requirements are met
	@command -v ansible-playbook >/dev/null || (echo "Missing: ansible-playbook ❌" && exit 1)
	@command -v ansible >/dev/null || (echo "Missing: ansible ❌" && exit 1)
	@command -v ansible-inventory >/dev/null || (echo "Missing: ansible-inventory ❌" && exit 1)
	@test -f inventory.ini || (echo "Missing: inventory.ini ❌" && exit 1)
	@ansible-inventory -i inventory.ini --list >/dev/null
	@echo "OK: tools + inventory ✅"

inventory: ## Get a graph of the ansible inventory
	@ansible-inventory --graph

ping: ## Ping all vms
	@ansible all -m ping

facts_identity: ## Get facts about basic identity of the hosts
	@ansible nodes -m setup -a 'filter=ansible_hostname,ansible_fqdn,ansible_distribution*,ansible_kernel,ansible_architecture,ansible_virtualization_*'

facts_network: ## Get facts about network configurations
	@ansible nodes -m setup -a 'filter=ansible_default_ipv4,ansible_interfaces,ansible_all_ipv4_addresses,ansible_all_ipv6_addresses'

facts_resources: ## Get facts about resources available to hosts
	@ansible nodes -m setup -a 'filter=ansible_processor_vcpus,ansible_memtotal_mb,ansible_memfree_mb,ansible_swaptotal_mb'

facts_storage: ## Get facts about storage devices and mounts
	@ansible nodes -m setup -a 'filter=ansible_devices,ansible_mounts'

host-prep: ## Main playbook which prepares the host, requires ansible
	@ansible-playbook host-prep.yaml

host-prep-dry: ## A dry run of the main playbook that prepares the host
	@ansible-playbook host-prep.yaml --check --diff

node-readiness: ## This is a readiness check of all vms created. This should be run only when the vms are actually created. (Look at terraform, for vm creation)
	@ansible-playbook node-readiness.yaml

lint: ## Run yamllint and ansible-lint if they're installed
	@echo "Running lint (only what is installed)..."
	@command -v yamllint >/dev/null && yamllint . || echo "SKIP: yamllint not installed"
	@command -v ansible-lint >/dev/null && ansible-lint . || echo "SKIP: ansible-lint not installed"

ssh-agent: ## Since we can't setup a ssh agent in Makefile we just paste the cmds needed to do that
	@echo `💡 Run these commands:`
	@echo 'eval "$$(ssh-agent -s)"'
	@echo 'ssh-add ~/.ssh/id_rsa'

help: ## Show this help.
	@echo ''
	@echo 'Usage:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} { \
		if (/^[a-zA-Z_-]+:.*?##.*$$/) {printf "    ${YELLOW}%-20s${GREEN}%s${RESET}\n", $$1, $$2} \
		else if (/^## .*$$/) {printf "  ${CYAN}%s${RESET}\n", substr($$1,4)} \
		}' $(MAKEFILE_LIST)


