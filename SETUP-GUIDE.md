# Complete Lab Setup Guide

This guide provides a comprehensive overview of the automated lab setup for the INTLUG Linux Networking presentation.

## Overview

The lab environment consists of 3 Fedora 43 virtual machines demonstrating:
- Dual-homed networking (public + isolated networks)
- Gateway/routing configuration with NAT
- DNS/DHCP services with dnsmasq
- Web services with nginx
- NetworkManager CLI and GUI tools
- Firewall configuration with firewalld

## Three Playbook Architecture

### 1. bootstrap-lab.yml - VM Creation & Initial Setup
**Purpose:** Create the complete infrastructure from scratch

**What it does:**
- Downloads Fedora 43 Cloud qcow2 image (~400MB)
- Generates SSH key pair (~/.ssh/id_fedora) if needed
- Creates 3 VMs with cloud-init:
  - labhost1: 192.168.122.151 (MAC: 52:54:00:00:00:01)
  - labhost2: 192.168.122.152 (MAC: 52:54:00:00:00:02)
  - labhost3: 192.168.122.153 (MAC: 52:54:00:00:00:03)
- Configures static DHCP leases in libvirt default network
- Provisions cloud-user account with SSH key
- Creates ansible user with NOPASSWD sudo
- Updates /etc/hosts on hypervisor

**Runs on:** localhost (hypervisor)

**Time:** ~5-10 minutes (depends on download speed)

### 2. provision-vms.yml - Network Interface Provisioning
**Purpose:** Add isolated network interfaces to VMs

**What it does:**
- Adds eth1 interface on isolated network (10.10.5.0/24) to each VM
- Temporarily shuts down VMs to attach interface
- Starts VMs back up
- Verifies SSH connectivity

**Runs on:** localhost (via libvirt API)

**Time:** ~2-3 minutes

### 3. site.yml - Service Configuration
**Purpose:** Configure all services, networking, and applications

**What it does:**
- Installs base packages and tools
- Configures NetworkManager interfaces
- Sets up firewall zones and rules
- Configures dnsmasq (DNS/DHCP) on labhost1
- Installs and configures nginx on labhost1
- Sets up NAT gateway (disabled by default)
- Installs GNOME on labhost3
- Installs monitoring tools (cockpit, PCP)

**Runs on:** All VMs (via SSH as ansible user)

**Time:** ~10-15 minutes

## Network Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    Hypervisor System                      │
│                                                           │
│  ┌────────────────────────────────────────────────────┐  │
│  │      Libvirt Default Network (NAT)                 │  │
│  │           192.168.122.0/24                         │  │
│  │                                                    │  │
│  │   ┌─────────────┐  ┌─────────────┐  ┌──────────┐ │  │
│  │   │  labhost1   │  │  labhost2   │  │ labhost3 │ │  │
│  │   │   .151      │  │   .152      │  │  .153    │ │  │
│  │   │ (Gateway)   │  │  (Client)   │  │ (GUI)    │ │  │
│  │   └──────┬──────┘  └──────────┬──┘  └────┬─────┘ │  │
│  └──────────┼────────────────────┼──────────┼────────┘  │
│             │                    │          │            │
│             │                    │          │            │
│  ┌──────────┴────────────────────┴──────────┴────────┐  │
│  │         Libvirt Isolated Network (No NAT)         │  │
│  │                10.10.5.0/24                       │  │
│  │                                                   │  │
│  │  labhost1: 10.10.5.10  (Static - Gateway/DNS)    │  │
│  │  labhost2: 10.10.5.51  (DHCP)                    │  │
│  │  labhost3: 10.10.5.52  (DHCP)                    │  │
│  └───────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

## Complete Setup Options

### Option 1: One-Command Setup (Easiest)

```bash
cd ansible
./setup-all.sh
```

This script runs all three playbooks in sequence with progress indicators.

### Option 2: Manual Step-by-Step

```bash
cd ansible

# Step 1: Create VMs
ansible-playbook bootstrap-lab.yml

# Verify VMs are up
ansible -i inventory demoservers -m ping

# Step 2: Add isolated network interfaces
ansible-playbook provision-vms.yml

# Step 3: Configure everything
ansible-playbook site.yml
```

### Option 3: Verification Before Each Step

```bash
cd ansible

# Check prerequisites
./verify-setup.sh

# Create VMs
ansible-playbook bootstrap-lab.yml

# Verify before provisioning
./verify-setup.sh

# Add interfaces
ansible-playbook provision-vms.yml

# Configure services
ansible-playbook site.yml
```

## Prerequisites

### Required Software (Fedora/RHEL)

```bash
sudo dnf install -y \
    ansible-core \
    libvirt \
    qemu-kvm \
    virt-install \
    genisoimage
```

### Required Software (Ubuntu/Debian)

```bash
sudo apt install -y \
    ansible \
    libvirt-daemon-system \
    qemu-kvm \
    virtinst \
    genisoimage
```

### User Configuration

```bash
# Add user to libvirt group
sudo usermod -aG libvirt $USER

# IMPORTANT: Log out and back in for group change to take effect
```

### Ansible Collections

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
```

### Verify Prerequisites

```bash
cd ansible
./verify-setup.sh
```

## File Structure

```
ansible/
├── bootstrap-lab.yml          # Playbook 1: Create VMs
├── provision-vms.yml          # Playbook 2: Add network interfaces
├── site.yml                   # Playbook 3: Configure services
├── setup-all.sh              # Run all playbooks in sequence
├── verify-setup.sh           # Verify prerequisites and status
├── BOOTSTRAP.md              # Detailed bootstrap documentation
├── README.md                 # Ansible documentation
├── ansible.cfg               # Ansible configuration
├── inventory                 # Host definitions
├── requirements.yml          # Required Ansible collections
│
├── group_vars/
│   ├── all.yml              # Global variables
│   └── gateway.yml          # Gateway-specific variables
│
└── roles/
    ├── base-packages/        # Install core packages
    ├── network-tools/        # Install networking utilities
    ├── network-config/       # Configure NetworkManager
    ├── monitoring/           # Set up cockpit & PCP
    ├── libvirt-config/       # Add VM network interfaces
    ├── dnsmasq/             # Configure DNS/DHCP
    ├── nginx/               # Configure web server
    ├── nat-gateway/         # Configure NAT routing
    └── gui-setup/           # Install GNOME desktop
```

## VM Specifications

### labhost1 (Gateway/Server)
- **Role:** Gateway, DNS, DHCP, Web Server
- **RAM:** 2 GB
- **CPUs:** 2
- **Disk:** 20 GB
- **Networks:**
  - eth0: 192.168.122.151 (public, NAT to internet)
  - eth1: 10.10.5.10 (isolated, static)
- **Services:**
  - dnsmasq (DNS/DHCP for isolated network)
  - nginx (web server and proxy)
  - NAT gateway (disabled by default for demos)
- **Firewall Zones:**
  - public: eth0 (SSH, HTTP allowed)
  - internal: eth1 (SSH, HTTP, DNS, DHCP, proxy)

### labhost2 (Isolated Client)
- **Role:** Client on isolated network
- **RAM:** 2 GB
- **CPUs:** 2
- **Disk:** 20 GB
- **Networks:**
  - eth0: 192.168.122.152 (initially, removed in final config)
  - eth1: 10.10.5.51 (isolated, DHCP from labhost1)
- **Purpose:** Test DNS, routing, and services from isolated network
- **Interface:** CLI only

### labhost3 (GUI Client)
- **Role:** Client with graphical interface
- **RAM:** 2 GB (may need more for GUI)
- **CPUs:** 2
- **Disk:** 20 GB
- **Networks:**
  - eth0: 192.168.122.153 (initially, removed in final config)
  - eth1: 10.10.5.52 (isolated, DHCP from labhost1)
- **Desktop:** GNOME (for demonstrating GUI network tools)
- **Purpose:** Show NetworkManager GUI tools, graphical troubleshooting

## Common Operations

### Start All VMs

```bash
virsh start labhost1
virsh start labhost2
virsh start labhost3
```

### Stop All VMs

```bash
virsh shutdown labhost1
virsh shutdown labhost2
virsh shutdown labhost3
```

### Access VMs

```bash
# SSH access (recommended)
ssh -i ~/.ssh/id_fedora ansible@labhost1.local
ssh -i ~/.ssh/id_fedora ansible@labhost2.local
ssh -i ~/.ssh/id_fedora ansible@labhost3.local

# Console access (for GUI or troubleshooting)
virsh console labhost1
virsh console labhost2
virsh console labhost3

# Press Ctrl+] to exit console
```

### Check VM Status

```bash
virsh list --all
```

### View VM Network Configuration

```bash
# On the VM
ssh ansible@labhost1.local 'nmcli device status'
ssh ansible@labhost1.local 'ip addr show'

# Or from Ansible
ansible -i ansible/inventory demoservers -m shell -a 'ip addr show'
```

### Test Services

```bash
# Test DNS from labhost2
ssh ansible@labhost2.local 'dig @10.10.5.10 labhost1.isolated'

# Test web server from labhost3
ssh ansible@labhost3.local 'curl http://labhost1.isolated'

# Check service status on labhost1
ssh ansible@labhost1.local 'systemctl status dnsmasq nginx'
```

## Resetting the Lab

### Complete Reset (Nuclear Option)

```bash
# Destroy VMs
virsh destroy labhost1 labhost2 labhost3
virsh undefine labhost1 labhost2 labhost3

# Remove disk images
sudo rm -f /var/lib/libvirt/images/labhost*.qcow2
sudo rm -f /var/lib/libvirt/images/labhost*-cidata.iso

# Recreate from scratch
cd ansible
ansible-playbook bootstrap-lab.yml
ansible-playbook provision-vms.yml
ansible-playbook site.yml
```

### Reset Configuration Only

```bash
# Keep VMs, just reconfigure
cd ansible
ansible-playbook site.yml
```

### Reset Single Role

```bash
# Just reconfigure networking
ansible-playbook site.yml --tags networking

# Just reconfigure services
ansible-playbook site.yml --tags services
```

## Troubleshooting

### VMs Won't Start

```bash
# Check libvirt service
sudo systemctl status libvirtd

# Check default network
virsh net-list --all
virsh net-start default
```

### Can't SSH to VMs

```bash
# Check VM is running
virsh list --all

# Check SSH port is open
nmap -p 22 192.168.122.151

# Try console access
virsh console labhost1
```

### Ansible Connection Issues

```bash
# Test manual SSH
ssh -i ~/.ssh/id_fedora ansible@192.168.122.151

# Check ansible.cfg settings
cat ansible/ansible.cfg

# Test with verbose output
ansible -i ansible/inventory demoservers -m ping -vvv
```

### Cloud-Init Not Completing

```bash
# Check cloud-init status
virsh console labhost1
# Login as cloud-user with SSH key or check status

# Or SSH and check
ssh -i ~/.ssh/id_fedora cloud-user@192.168.122.151
sudo cloud-init status
```

### Playbook Failures

```bash
# Run with increased verbosity
ansible-playbook bootstrap-lab.yml -vvv

# Check specific task
ansible-playbook site.yml --start-at-task="Task Name"

# Run specific tags only
ansible-playbook site.yml --tags base,networking
```

## Advanced Topics

### Customizing VM Resources

Edit [bootstrap-lab.yml](ansible/bootstrap-lab.yml) `vms` variable:

```yaml
vms:
  - name: labhost1
    memory: 4096  # 4 GB RAM
    vcpus: 4      # 4 CPUs
    disk_size: 30 # 30 GB disk
```

### Using Different Fedora Version

Edit [bootstrap-lab.yml](ansible/bootstrap-lab.yml):

```yaml
fedora_version: "44"  # Change to desired version
```

### Adding More VMs

1. Add VM to `vms` list in bootstrap-lab.yml
2. Add hostname to ansible/inventory
3. Add any specific configuration in group_vars/

### Enabling NAT on labhost1

```bash
# SSH to labhost1
ssh ansible@labhost1.local

# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Add firewall masquerading
sudo firewall-cmd --zone=public --add-masquerade

# Make permanent
sudo firewall-cmd --permanent --zone=public --add-masquerade
sudo sh -c 'echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf'
```

## For Presentation

### Demo Scenarios

1. **Network Configuration**
   - Show nmcli commands on labhost1
   - Show GNOME settings on labhost3

2. **DNS/DHCP**
   - Query DNS from labhost2
   - Show dnsmasq config on labhost1

3. **Routing**
   - Enable NAT on labhost1
   - Test internet access from labhost2

4. **Firewall**
   - Show firewalld zones
   - Add/remove services

5. **Web Services**
   - Access nginx on labhost1
   - Test proxy configuration

### Useful Commands for Demo

```bash
# Network status
nmcli device status
nmcli connection show

# IP configuration
ip addr show
ip route show

# DNS testing
dig @10.10.5.10 labhost1.isolated
nslookup labhost1.isolated 10.10.5.10

# Connectivity testing
ping -c 3 labhost1.isolated
traceroute labhost1.isolated

# Service testing
curl http://labhost1.isolated
nc -zv labhost1.isolated 80

# Firewall
firewall-cmd --list-all-zones
firewall-cmd --get-active-zones
```

## Resources

- **Bootstrap Documentation:** [ansible/BOOTSTRAP.md](ansible/BOOTSTRAP.md)
- **Lab Architecture:** [LAB-SETUP.md](LAB-SETUP.md)
- **Ansible Details:** [ansible/README.md](ansible/README.md)
- **Presentation Slides:** [slides.md](slides.md)

## Support

For issues or questions:
1. Check [ansible/BOOTSTRAP.md](ansible/BOOTSTRAP.md) troubleshooting section
2. Review Ansible playbook output for errors
3. Use `./verify-setup.sh` to check prerequisites
4. Check VM console with `virsh console <vm_name>`
