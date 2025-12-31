# Quick Reference - Lab Commands

## Setup Commands

```bash
# Complete automated setup
cd ansible && ./setup-all.sh

# Or step-by-step
cd ansible
ansible-playbook bootstrap-lab.yml    # Create VMs (~5-10 min)
ansible-playbook provision-vms.yml    # Add interfaces (~2-3 min)
ansible-playbook site.yml             # Configure services (~10-15 min)

# Verify setup
./verify-setup.sh
ansible -i inventory demoservers -m ping
```

## VM Management

```bash
# List VMs
virsh list --all

# Start/Stop VMs
virsh start labhost1
virsh shutdown labhost1
virsh destroy labhost1    # Force stop

# Start all lab VMs
virsh start labhost1 && virsh start labhost2 && virsh start labhost3

# Console access
virsh console labhost1    # Ctrl+] to exit
```

## SSH Access

```bash
# SSH to VMs
ssh -i ~/.ssh/id_fedora ansible@labhost1.local
ssh -i ~/.ssh/id_fedora ansible@labhost2.local
ssh -i ~/.ssh/id_fedora ansible@labhost3.local

# Or using IPs
ssh -i ~/.ssh/id_fedora ansible@192.168.122.151  # labhost1
ssh -i ~/.ssh/id_fedora ansible@192.168.122.152  # labhost2
ssh -i ~/.ssh/id_fedora ansible@192.168.122.153  # labhost3
```

## Network Information

```bash
# VM IPs
# Public Network (192.168.122.0/24):
#   labhost1: 192.168.122.151
#   labhost2: 192.168.122.152
#   labhost3: 192.168.122.153
#
# Isolated Network (10.10.5.0/24):
#   labhost1: 10.10.5.10 (static)
#   labhost2: 10.10.5.51 (DHCP)
#   labhost3: 10.10.5.52 (DHCP)

# Check network status
virsh net-list --all
virsh net-info default
```

## Testing Services

```bash
# Test DNS from labhost2
ssh ansible@labhost2.local 'dig @10.10.5.10 labhost1.isolated'
ssh ansible@labhost2.local 'nslookup labhost1.isolated 10.10.5.10'

# Test web server
ssh ansible@labhost2.local 'curl http://labhost1.isolated'
ssh ansible@labhost3.local 'curl http://10.10.5.10'

# Check service status on labhost1
ssh ansible@labhost1.local 'systemctl status dnsmasq'
ssh ansible@labhost1.local 'systemctl status nginx'

# Test connectivity
ssh ansible@labhost2.local 'ping -c 3 labhost1.isolated'
ssh ansible@labhost3.local 'ping -c 3 10.10.5.10'
```

## NetworkManager Commands (nmcli)

```bash
# Show device status
nmcli device status

# Show all connections
nmcli connection show

# Show specific connection details
nmcli connection show eth1

# Show IP addresses
nmcli -p device show eth1

# Restart connection
nmcli connection down eth1
nmcli connection up eth1

# Reload configuration
nmcli connection reload
```

## IP Commands

```bash
# Show all interfaces
ip addr show
ip a

# Show specific interface
ip addr show eth1

# Show routing table
ip route show
ip r

# Show neighbors (ARP)
ip neighbor show
```

## Firewall Commands (firewalld)

```bash
# Show all zones
firewall-cmd --list-all-zones

# Show active zones
firewall-cmd --get-active-zones

# Show specific zone
firewall-cmd --zone=public --list-all

# Check if service is allowed
firewall-cmd --zone=public --list-services

# Add service temporarily
firewall-cmd --zone=public --add-service=http

# Add service permanently
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --reload
```

## DNS Testing

```bash
# Query DNS server
dig @10.10.5.10 labhost1.isolated
dig @10.10.5.10 labhost2.isolated
dig @10.10.5.10 labhost3.isolated

# Use nslookup
nslookup labhost1.isolated 10.10.5.10

# Check /etc/resolv.conf
cat /etc/resolv.conf

# Test resolution
host labhost1.isolated 10.10.5.10
```

## Connectivity Testing

```bash
# Ping test
ping -c 3 labhost1.isolated
ping -c 3 10.10.5.10

# Traceroute
traceroute labhost1.isolated

# Port scanning
nc -zv labhost1.isolated 80
nmap -p 80,443 labhost1.isolated

# Web testing
curl http://labhost1.isolated
curl -I http://10.10.5.10
wget http://labhost1.isolated -O /dev/null
```

## Monitoring Tools

```bash
# Network interface stats
ip -s link show eth1
ifstat

# Real-time bandwidth
nload eth1
iftop -i eth1

# Network connections
ss -tuln          # Listening ports
ss -tunap         # All connections
netstat -tuln     # Alternative

# Packet capture
tcpdump -i eth1
tcpdump -i eth1 port 80
tcpdump -i eth1 -w capture.pcap
```

## Service Management

```bash
# Status
systemctl status dnsmasq
systemctl status nginx
systemctl status cockpit

# Start/Stop
sudo systemctl start dnsmasq
sudo systemctl stop nginx
sudo systemctl restart cockpit

# Enable/Disable at boot
sudo systemctl enable dnsmasq
sudo systemctl disable nginx
```

## Log Viewing

```bash
# System logs
journalctl -xe
journalctl -u dnsmasq
journalctl -u nginx
journalctl -f            # Follow

# dnsmasq logs
journalctl -u dnsmasq -n 50
tail -f /var/log/messages | grep dnsmasq

# nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

## Ansible Quick Commands

```bash
# Ping all hosts
ansible -i ansible/inventory demoservers -m ping

# Run command on all hosts
ansible -i ansible/inventory demoservers -a "uptime"

# Run command on specific group
ansible -i ansible/inventory gateway -a "systemctl status dnsmasq"

# Run with sudo
ansible -i ansible/inventory demoservers -b -a "dnf update -y"

# Gather facts
ansible -i ansible/inventory labhost1.local -m setup
```

## Reset/Cleanup

```bash
# Reconfigure everything
cd ansible && ansible-playbook site.yml

# Reconfigure specific role
ansible-playbook site.yml --tags networking

# Complete reset
virsh destroy labhost{1,2,3}
virsh undefine labhost{1,2,3}
sudo rm -f /var/lib/libvirt/images/labhost*.qcow2
sudo rm -f /var/lib/libvirt/images/labhost*-cidata.iso

# Then rebuild
cd ansible
ansible-playbook bootstrap-lab.yml
ansible-playbook provision-vms.yml
ansible-playbook site.yml
```

## Useful One-Liners

```bash
# Check if all VMs are running
virsh list --name --state-running | grep labhost | wc -l

# Get all VM IPs
for vm in labhost{1,2,3}; do 
  echo -n "$vm: "
  virsh domifaddr $vm | grep ipv4 | awk '{print $4}'
done

# Test connectivity to all VMs
for i in {151..153}; do 
  ping -c 1 192.168.122.$i && echo "labhost$((i-150)): UP" || echo "labhost$((i-150)): DOWN"
done

# Check services on labhost1
ssh ansible@labhost1.local 'for svc in dnsmasq nginx cockpit; do systemctl is-active $svc && echo "$svc: UP" || echo "$svc: DOWN"; done'

# Show all network interfaces on all VMs
ansible -i ansible/inventory demoservers -a "ip -br addr"
```

## Demo Preparation

```bash
# Enable NAT on labhost1 for demo
ssh ansible@labhost1.local << 'EOF'
  sudo sysctl -w net.ipv4.ip_forward=1
  sudo firewall-cmd --zone=public --add-masquerade
EOF

# Disable NAT after demo
ssh ansible@labhost1.local << 'EOF'
  sudo sysctl -w net.ipv4.ip_forward=0
  sudo firewall-cmd --zone=public --remove-masquerade
EOF

# Restart service for demo
ssh ansible@labhost1.local 'sudo systemctl restart nginx'

# Clear logs for clean demo
ssh ansible@labhost1.local 'sudo journalctl --rotate && sudo journalctl --vacuum-time=1s'
```

## Troubleshooting

```bash
# Can't reach VM
virsh list --all                    # Check if running
virsh console labhost1              # Console access
virsh domiflist labhost1            # Check interfaces
ping 192.168.122.151               # Test connectivity

# DNS not working
ssh ansible@labhost1.local 'sudo systemctl status dnsmasq'
ssh ansible@labhost2.local 'cat /etc/resolv.conf'
ssh ansible@labhost2.local 'dig @10.10.5.10 labhost1.isolated'

# Web server not accessible
ssh ansible@labhost1.local 'sudo systemctl status nginx'
ssh ansible@labhost1.local 'sudo firewall-cmd --zone=public --list-all'
ssh ansible@labhost1.local 'sudo ss -tuln | grep :80'

# Ansible connection issues
ssh -i ~/.ssh/id_fedora ansible@192.168.122.151   # Test manual SSH
ansible -i ansible/inventory demoservers -m ping -vvv  # Verbose output
cat ansible/ansible.cfg                           # Check config
```

## Documentation

- Setup Guide: [SETUP-GUIDE.md](SETUP-GUIDE.md)
- Bootstrap Details: [ansible/BOOTSTRAP.md](ansible/BOOTSTRAP.md)
- Lab Architecture: [LAB-SETUP.md](LAB-SETUP.md)
- Ansible Guide: [ansible/README.md](ansible/README.md)
