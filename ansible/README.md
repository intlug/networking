# Ansible Lab Setup

This directory contains Ansible playbooks and roles to configure the lab environment for the Linux Networking presentation.

## Structure

```
ansible/
├── ansible.cfg           # Ansible configuration
├── inventory            # Host inventory file
├── provision-vms.yml   # VM provisioning (add NICs via libvirt)
├── site.yml            # Main configuration playbook
├── group_vars/         # Group variables
│   ├── all.yml        # Variables for all hosts
│   └── gateway.yml    # Gateway-specific variables
└── roles/             # Ansible roles
    ├── libvirt-config/    # Add NICs to VMs
    ├── base-packages/
    ├── monitoring/
    ├── network-tools/
    ├── network-config/
    ├── dnsmasq/
    ├── nginx/
    ├── nat-gateway/
    └── gui-setup/
```

## Prerequisites

1. Three Fedora 43 VMs running with:
   - Hostname: labhost1, labhost2, labhost3
   - User: ansible (with sudo privileges, key-based auth)
   - SSH key: ~/.ssh/id_fedora
   - Both eth0 (public) and eth1 (isolated) interfaces attached

2. Install Ansible on control node (hypervisor):
   ```bash
   sudo dnf install ansible-core
   ```

3. Install required Ansible collections:
   ```bash
   cd ansible
   ansible-galaxy collection install -r requirements.yml
   ```

## Usage

### Initial Setup

1. Install required collections:
```bash
ansible-galaxy collection install -r requirements.yml
```

2. Verify connectivity to all hosts:
```bash
ansible all -m ping
```

3. **Step 1: Provision VMs** - Add isolated network interfaces:
```bash
ansible-playbook provision-vms.yml
```
This will:
- Add eth1 (isolated network interface) to each VM via libvirt
- Temporarily shut down and restart VMs
- Verify SSH connectivity after restart

4. **Step 2: Configure VMs** - Run the main configuration:
```bash
ansible-playbook site.yml
```
This will configure all services, networking, and applications.

### Run Specific Roles

Run specific stages of setup:
```bash
# Base packages and tools only
ansible-playbook site.yml --tags base

# Network configuration only
ansible-playbook site.yml --tags networking

# Services only (dnsmasq, nginx)
ansible-playbook site.yml --tags services
```

### Post-Installation Verification

Check services on labhost1:
```bash
ansible gateway -m shell -a "systemctl status dnsmasq nginx"
ansible gateway -m shell -a "firewall-cmd --list-all-zones"
```

Test DNS from internal hosts:
```bash
ansible labhost2.local -m shell -a "dig @10.10.5.10 labhost1.isolated"
ansible labhost3.local -m shell -a "nslookup labhost2.isolated"
```

Test web server:
```bash
ansible gateway -m shell -a "curl -s http://localhost"
```

## Configuration

See [LAB-SETUP.md](../LAB-SETUP.md) for detailed architecture and configuration requirements.

### Key Variables

Edit `group_vars/all.yml` to customize:
- Network ranges and IPs
- DHCP configuration
- Firewall zones and services

Edit `group_vars/gateway.yml` to configure:
- NAT and IP forwarding settings (disabled by default for demo)
- Interface names

## Manual Demo Steps

After running the playbooks, some features are configured but disabled for live demonstration:

### Enable NAT on labhost1:
```bash
# On labhost1
sudo sysctl -w net.ipv4.ip_forward=1
sudo firewall-cmd --zone=external --add-masquerade
```

### Disable NAT:
```bash
sudo firewall-cmd --zone=external --remove-masquerade
sudo sysctl -w net.ipv4.ip_forward=0
```
