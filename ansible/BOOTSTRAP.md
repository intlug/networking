# Bootstrap Lab Environment

This playbook automates the complete setup of the INTLUG networking lab from scratch.

## What It Does

The `bootstrap-lab.yml` playbook performs the following tasks:

1. **Downloads Fedora Cloud Image** - Fetches the Fedora 43 Cloud Base qcow2 image
2. **Creates SSH Key** - Generates `~/.ssh/id_fedora` if it doesn't exist
3. **Creates 3 VMs** - Uses libvirt/KVM to create labhost1, labhost2, and labhost3
4. **Configures Static IPs** - Updates libvirt default network with DHCP reservations:
   - labhost1.local → 192.168.122.151 (MAC: 52:54:00:00:00:01)
   - labhost2.local → 192.168.122.152 (MAC: 52:54:00:00:00:02)
   - labhost3.local → 192.168.122.153 (MAC: 52:54:00:00:00:03)
5. **Provisions Cloud-Init** - Sets up cloud-user with SSH key access
6. **Creates Ansible User** - Adds ansible user with NOPASSWD sudo on all VMs
7. **Updates /etc/hosts** - Adds hostname entries for easy access

## Prerequisites

### Required Software

```bash
# Fedora/RHEL/CentOS
sudo dnf install -y ansible libvirt qemu-kvm virt-install genisoimage guestfs-tools

# Ubuntu/Debian
sudo apt install -y ansible libvirt-daemon-system qemu-kvm virtinst genisoimage libguestfs-tools

# Arch
sudo pacman -S ansible libvirt qemu-full virt-install cdrtools libguestfs
```

**Note:** `guestfs-tools` (or `libguestfs-tools`) provides `virt-cat`, `virt-ls`, and `guestfish` utilities for VM debugging.

### Required Ansible Collections

```bash
ansible-galaxy collection install -r requirements.yml
```

### User Configuration

Your user must be in the `libvirt` group:

```bash
sudo usermod -aG libvirt $USER
```

**Important:** Log out and back in for group changes to take effect!

Verify you can access libvirt without sudo:

```bash
virsh list --all
```

### Libvirt Default Network

Ensure the default network is active:

```bash
virsh -c qemu:///system net-list --all
```

If not active:

```bash
virsh net-start default
virsh net-autostart default
```

## Quick Start

### Complete Lab Setup (One Command)

```bash
# From the ansible directory
ansible-playbook bootstrap-lab.yml
```

This will take 5-10 minutes depending on your internet connection and system speed.

### Step-by-Step Setup

If you prefer to run each phase separately:

```bash
# 1. Bootstrap VMs (create infrastructure)
ansible-playbook bootstrap-lab.yml

# 2. Add isolated network interfaces
ansible-playbook provision-vms.yml

# 3. Configure services and networking
ansible-playbook site.yml
```

## What Gets Created

### Virtual Machines

Three Fedora 43 VMs with:
- 2 GB RAM each
- 2 vCPUs each
- 20 GB disk each
- qemu-guest-agent installed
- Multi-user target (no GUI by default)

### Network Configuration

**Default Network (192.168.122.0/24)**
- All VMs initially connected
- Static DHCP leases configured
- NAT to internet

**Isolated Network (10.10.5.0/24)**
- Added by provision-vms.yml
- Only labhost1 initially has routing capability

### User Accounts

Each VM has two users:

1. **cloud-user** - Created by cloud-init, has sudo access
2. **ansible** - Created by bootstrap, used for automation

Both use the SSH key at `~/.ssh/id_fedora`

## Verification

### Test Ansible Connectivity

```bash
ansible -i inventory demoservers -m ping
```

Expected output:
```
labhost1.local | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
labhost2.local | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
labhost3.local | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### Test SSH Access

```bash
ssh -i ~/.ssh/id_fedora ansible@labhost1.local
ssh -i ~/.ssh/id_fedora ansible@labhost2.local
ssh -i ~/.ssh/id_fedora ansible@labhost3.local
```

### Check VM Status

```bash
virsh list --all
```

Should show all three VMs running.

## Troubleshooting

### Permission Denied

If you get permission errors:

```bash
# Ensure you're in the libvirt group
groups | grep libvirt

# If not, add yourself and log out/in
sudo usermod -aG libvirt $USER
```

### VMs Won't Start

```bash
# Check libvirt service
sudo systemctl status libvirtd

# Check default network
virsh net-list --all
virsh net-start default
```

### SSH Connection Refused

```bash
# Wait for cloud-init to complete (may take 1-2 minutes)
# Check VM console
virsh console labhost1

# Press Ctrl+] to exit console
```

### Image Download Fails

If the Fedora image URL is outdated:

1. Visit https://fedoraproject.org/cloud/download/
2. Find the latest Cloud Base x86_64 qcow2 image
3. Update `fedora_cloud_image_url` in bootstrap-lab.yml

### Clean Start

To completely remove VMs and start over:

```bash
# Destroy VMs
virsh destroy labhost1 labhost2 labhost3
virsh undefine labhost1 labhost2 labhost3

# Remove disk images
sudo rm -f /var/lib/libvirt/images/labhost*.qcow2
sudo rm -f /var/lib/libvirt/images/labhost*-cidata.iso

# Remove DHCP entries (optional)
virsh net-update default delete ip-dhcp-host \
  "<host mac='52:54:00:00:00:01'/>" --config
virsh net-update default delete ip-dhcp-host \
  "<host mac='52:54:00:00:00:02'/>" --config
virsh net-update default delete ip-dhcp-host \
  "<host mac='52:54:00:00:00:03'/>" --config

# Run bootstrap again
ansible-playbook bootstrap-lab.yml
```

## Customization

### Change VM Resources

Edit the `vms` variable in bootstrap-lab.yml:

```yaml
vms:
  - name: labhost1
    memory: 4096  # 4 GB
    vcpus: 4      # 4 CPUs
    disk_size: 30 # 30 GB disk
```

### Change IP Addresses

Update both the playbook and inventory file to match.

### Use Different Fedora Version

Change `fedora_version` variable in bootstrap-lab.yml.

## Next Steps

After bootstrap completes:

1. **Add Isolated Network**
   ```bash
   ansible-playbook provision-vms.yml
   ```

2. **Configure Services**
   ```bash
   ansible-playbook site.yml
   ```

3. **Verify Setup**
   ```bash
   # Check labhost1 can act as gateway
   ssh ansible@labhost1.local
   
   # Check labhost3 has GUI available
   virsh console labhost3
   ```

## Architecture Overview

```
┌─────────────────────────────────────────────┐
│           Hypervisor (Your Machine)         │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │   Libvirt Default Network (NAT)     │   │
│  │       192.168.122.0/24              │   │
│  │                                     │   │
│  │  ┌──────┐  ┌──────┐  ┌──────┐     │   │
│  │  │ VM1  │  │ VM2  │  │ VM3  │     │   │
│  │  │.151  │  │.152  │  │.153  │     │   │
│  │  └──┬───┘  └──┬───┘  └──┬───┘     │   │
│  └─────┼─────────┼─────────┼─────────┘   │
│        │         │         │               │
│  ┌─────┴─────────┴─────────┴─────────┐   │
│  │   Isolated Network (No NAT)       │   │
│  │       10.10.5.0/24                │   │
│  │                                   │   │
│  │   VM1: 10.10.5.10 (Gateway)       │   │
│  │   VM2: 10.10.5.51 (DHCP)          │   │
│  │   VM3: 10.10.5.52 (DHCP+GUI)      │   │
│  └───────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

## Files Created

- `/var/lib/libvirt/images/fedora-43-cloud-base.qcow2` - Base image
- `/var/lib/libvirt/images/labhost[1-3].qcow2` - VM disks
- `/var/lib/libvirt/images/labhost[1-3]-cidata.iso` - Cloud-init configs
- `~/.ssh/id_fedora` - SSH private key
- `~/.ssh/id_fedora.pub` - SSH public key

## Support

For issues related to:
- **Ansible playbooks** - Check ansible/README.md
- **Lab architecture** - See LAB-SETUP.md
- **Networking concepts** - Refer to the presentation slides.md
