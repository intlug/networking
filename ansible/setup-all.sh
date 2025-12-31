#!/bin/bash
# Complete lab setup script - runs all three playbooks in sequence
# Usage: ./setup-all.sh [network_prefix]
# Example: ./setup-all.sh 192.168.132
# Default: 192.168.122

set -e

# Network prefix - use parameter or default to 192.168.122
PUBLIC_PREFIX="${1:-192.168.122}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() {
    echo -e "${BLUE}==>${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}!${NC} $1"
}

echo ""
echo "=============================================="
echo "  INTLUG Networking Lab - Complete Setup"
echo "=============================================="
echo ""

# Check if running from ansible directory
if [ ! -f "ansible.cfg" ]; then
    echo "Error: Please run this script from the ansible/ directory"
    exit 1
fi

# Ask for confirmation
echo "This script will:"
echo "  1. Create 3 Fedora VMs (bootstrap-lab.yml)"
echo "  2. Add isolated network interfaces (provision-vms.yml)"
echo "  3. Configure all services (site.yml)"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
info "Starting complete lab setup..."
echo ""

# Step 1: Bootstrap
info "Step 1/3: Bootstrapping VMs (this may take 5-10 minutes)..."
echo ""
if ansible-playbook -e "public_network_prefix=${PUBLIC_PREFIX}" bootstrap-lab.yml; then
    success "Bootstrap completed successfully"
    echo ""
else
    echo ""
    echo "Error: Bootstrap failed. Please check the output above."
    exit 1
fi

# Wait a moment
sleep 5

# Step 2: Provision
info "Step 2/3: Adding isolated network interfaces..."
echo ""
if ansible-playbook -e "public_network_prefix=${PUBLIC_PREFIX}" provision-vms.yml; then
    success "Provisioning completed successfully"
    echo ""
else
    echo ""
    echo "Error: Provisioning failed. Please check the output above."
    exit 1
fi

# Wait for VMs to come back up
info "Waiting for VMs to stabilize..."
sleep 10

# Step 3: Configure
info "Step 3/3: Configuring services and networking..."
echo ""
if ansible-playbook -e "public_network_prefix=${PUBLIC_PREFIX}" site.yml; then
    success "Configuration completed successfully"
    echo ""
else
    echo ""
    echo "Error: Configuration failed. Please check the output above."
    exit 1
fi

echo ""
echo "=============================================="
echo "  Lab Setup Complete!"
echo "=============================================="
echo ""
echo "Your lab environment is ready!"
echo ""
echo "Network: ${PUBLIC_PREFIX}.0/24"
echo ""
echo "VM Details:"
echo "  • labhost1.local (${PUBLIC_PREFIX}.151)"
echo "    - Gateway/Router"
echo "    - DNS/DHCP server (dnsmasq)"
echo "    - Web server (nginx)"
echo "    - Dual-homed (public + isolated)"
echo ""
echo "  • labhost2.local (${PUBLIC_PREFIX}.152)"
echo "    - Client on isolated network only"
echo "    - Tests routing through labhost1"
echo ""
echo "  • labhost3.local (${PUBLIC_PREFIX}.153)"
echo "    - Client on isolated network only"
echo "    - GUI available (GNOME)"
echo "    - Tests routing through labhost1"
echo ""
echo "Access VMs:"
echo "  ssh -i ~/.ssh/id_fedora ansible@labhost1.local"
echo "  ssh -i ~/.ssh/id_fedora ansible@labhost2.local"
echo "  ssh -i ~/.ssh/id_fedora ansible@labhost3.local"
echo ""
echo "Or with console:"
echo "  virsh console labhost3  # Press Ctrl+] to exit"
echo ""
echo "Test the setup:"
echo "  # From labhost1, check services"
echo "  ssh ansible@labhost1.local 'systemctl status dnsmasq nginx'"
echo ""
echo "  # From labhost2, test DNS"
echo "  ssh ansible@labhost2.local 'dig @10.10.5.10 labhost1.isolated'"
echo ""
echo "  # From labhost3, test web access"
echo "  ssh ansible@labhost3.local 'curl http://labhost1.isolated'"
echo ""
echo "For presentation slides:"
echo "  cd .. && npm start"
echo ""
