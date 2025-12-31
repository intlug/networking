#!/bin/bash
# Test script to verify lab environment is properly configured

set -e

echo "======================================"
echo "INTLUG Networking Lab - Verification"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

success() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

warning() {
    echo -e "${YELLOW}!${NC} $1"
}

# Check if running from ansible directory
if [ ! -f "ansible.cfg" ]; then
    error "Please run this script from the ansible/ directory"
    exit 1
fi

echo "1. Checking prerequisites..."
echo ""

# Check if libvirt is running
if systemctl is-active --quiet libvirtd; then
    success "libvirtd is running"
else
    error "libvirtd is not running"
    echo "  Run: sudo systemctl start libvirtd"
    exit 1
fi

# Check if default network is active
if virsh net-list | grep -q "default.*active"; then
    success "libvirt default network is active"
else
    error "libvirt default network is not active"
    echo "  Run: virsh net-start default"
    exit 1
fi

# Check if user is in libvirt group
if groups | grep -q libvirt; then
    success "User is in libvirt group"
else
    error "User is not in libvirt group"
    echo "  Run: sudo usermod -aG libvirt \$USER"
    echo "  Then log out and back in"
    exit 1
fi

# Check if SSH key exists
if [ -f ~/.ssh/id_fedora ]; then
    success "SSH key exists (~/.ssh/id_fedora)"
else
    warning "SSH key not found - will be created by bootstrap"
fi

# Check if ansible is installed
if command -v ansible-playbook &> /dev/null; then
    success "Ansible is installed ($(ansible --version | head -n1))"
else
    error "Ansible is not installed"
    echo "  Run: sudo dnf install ansible-core"
    exit 1
fi

# Check required collections
echo ""
echo "2. Checking Ansible collections..."
echo ""

COLLECTIONS=("community.general" "ansible.posix" "community.libvirt")
for collection in "${COLLECTIONS[@]}"; do
    if ansible-galaxy collection list | grep -q "$collection"; then
        success "$collection is installed"
    else
        error "$collection is not installed"
        echo "  Run: ansible-galaxy collection install -r requirements.yml"
        exit 1
    fi
done

# Check if VMs exist
echo ""
echo "3. Checking VMs..."
echo ""

VMS=("labhost1" "labhost2" "labhost3")
all_running=true
any_exist=false

for vm in "${VMS[@]}"; do
    if virsh list --all | grep -q "$vm"; then
        any_exist=true
        if virsh list --state-running | grep -q "$vm"; then
            success "$vm is running"
        else
            warning "$vm exists but is not running"
            all_running=false
        fi
    else
        warning "$vm does not exist"
        all_running=false
    fi
done

if [ "$any_exist" = false ]; then
    warning "No VMs found - run bootstrap-lab.yml to create them"
fi

# Test SSH connectivity if VMs are running
if [ "$all_running" = true ] && [ -f ~/.ssh/id_fedora ]; then
    echo ""
    echo "4. Testing SSH connectivity..."
    echo ""
    
    HOSTS=("192.168.122.151" "192.168.122.152" "192.168.122.153")
    NAMES=("labhost1" "labhost2" "labhost3")
    
    for i in "${!HOSTS[@]}"; do
        if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null \
               -i ~/.ssh/id_fedora ansible@${HOSTS[$i]} 'echo test' &>/dev/null; then
            success "SSH to ${NAMES[$i]} (${HOSTS[$i]}) working"
        else
            error "Cannot SSH to ${NAMES[$i]} (${HOSTS[$i]})"
        fi
    done
    
    echo ""
    echo "5. Testing Ansible connectivity..."
    echo ""
    
    if ansible -i inventory demoservers -m ping &>/dev/null; then
        success "Ansible can reach all hosts"
    else
        error "Ansible connectivity failed"
        echo "  Run: ansible -i inventory demoservers -m ping"
    fi
fi

echo ""
echo "======================================"
echo "Summary"
echo "======================================"
echo ""

if [ "$any_exist" = false ]; then
    echo -e "${YELLOW}No VMs found.${NC} Ready to bootstrap!"
    echo ""
    echo "Next step:"
    echo "  ansible-playbook bootstrap-lab.yml"
elif [ "$all_running" = true ]; then
    echo -e "${GREEN}Lab environment is ready!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. ansible-playbook provision-vms.yml  # Add isolated network"
    echo "  2. ansible-playbook site.yml          # Configure services"
else
    echo -e "${YELLOW}VMs exist but not all are running.${NC}"
    echo ""
    echo "To start VMs:"
    for vm in "${VMS[@]}"; do
        echo "  virsh start $vm"
    done
    echo ""
    echo "Or destroy and recreate:"
    echo "  ansible-playbook bootstrap-lab.yml"
fi

echo ""
