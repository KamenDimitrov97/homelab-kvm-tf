SHELL := /bin/bash

GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
CYAN   := $(shell tput -Txterm setaf 6)
RESET  := $(shell tput -Txterm sgr0)

VMS := cp1 cp2 cp3 storage1 w1 w2
STOP_VMS := w2 w1 storage1 cp3 cp2 cp1

.PHONY: init plan apply destroy up down reboot status ssh help
ssh: ## Explain ssh connectivity to vms
	@echo 'In order to connect to one of the vms via ssh'
	@echo 'I recommend to use eval "$(ssh-agent -s)".'
	@echo ''
	@echo 'After recreation of vms you might receive an err msg'
	@echo 'regarding a "REMOTE HOST IDENTIFICATION HAS CHANGED!"'
	@echo ''
	@echo 'Host identity has changes due to recreation of the said vm'
	@echo 'in order to fix: "ssh-keygen -f ~/.ssh/known_hosts -R <vm-hostname>"'

init: ## Runs terraform init
	@terraform init 

plan: ## Runs terraform plan
	@terraform plan

apply: ## Runs terraform apply
	@terraform apply

destroy: ## Runs terraform destroy
	terraform destroy

list: ## list all vms
	@virsh list --all

status: ## get status from all vms
	@for vm in $(VMS); do \
	  st="$$(virsh domstate $$vm 2>/dev/null)"; \
	  if [[ -z "$$st" ]]; then \
	    echo "$$vm: not found"; \
	  else \
	    echo "$$vm: $$st"; \
	  fi; \
	done

up: ## start all vms
	@for vm in $(VMS); do \
	  st="$$(virsh domstate $$vm 2>/dev/null)"; \
	  if [[ "$$st" == "running" ]]; then \
	    echo "SKIP  $$vm (already running)"; \
	  elif [[ -z "$$st" ]]; then \
	    echo "WARN  $$vm (domain not found)"; \
	  else \
	    echo "START $$vm"; \
	    virsh start $$vm >/dev/null; \
	  fi; \
	done

down:  ## shuts off all vm
	@for vm in $(shell echo $(VMS) | awk '{for(i=NF;i>=1;i--) printf "%s ",$$i}'); do \
	  st="$$(virsh domstate $$vm 2>/dev/null)"; \
	  if [[ "$$st" == "shut off" || "$$st" == "shutdown" ]]; then \
	    echo "SKIP  $$vm (already off)"; \
	  elif [[ -z "$$st" ]]; then \
	    echo "WARN  $$vm (domain not found)"; \
	  else \
	    echo "STOP  $$vm (shutdown)"; \
	    virsh shutdown $$vm >/dev/null || true; \
	  fi; \
	done

reboot: ## reboots all vms
	@for vm in $(VMS); do \
	  st="$$(virsh domstate $$vm 2>/dev/null)"; \
	  if [[ "$$st" != "running" ]]; then \
	    echo "SKIP  $$vm (not running)"; \
	  else \
	    echo "REBOOT $$vm"; \
	    virsh reboot $$vm >/dev/null || true; \
	  fi; \
	done

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
