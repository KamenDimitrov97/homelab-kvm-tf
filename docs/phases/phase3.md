
# Phase 3 — IPs + basic node readiness
1. Configure DHCP reservations on router for:
   - `cp1 cp2 cp3 w1 w2 storage1` ✅
2. Verify:
   - all VMs reachable via SSH✅
   - all nodes can reach each other (temporary `/etc/hosts` is fine)✅
   - time sync is working (chrony/systemd-timesyncd)✅

**Deliverable:** clean connectivity + stable addressing.

# Soultions

## DHCP reservations

DHCP - dynamic host configuration protocol. 
This protocol is responsible for automatically assigning network settings like:
IP Address, Subnet mask, Default Gateway.

