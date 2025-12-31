# Introduction

The setup is to be used to showcase networking features of Linux using Fedora. It will show-case several of the areas mentioned in the presentation. Using Ansible, the lab will be configured/prepared. Use as many galaxy pre defined collections/roles as possible.

# Initial architecture

I've configured 3 libvirt VMs with Fedora 43. They're named labhost1, labhost2, labhost3 on libvirt. virsh will allow this local user to access all VMs. Each VM uses the same base image making resetting the environment easy, and does not require ansible to install each host.

The local host file will resolve labhost1-3, but here are the details

* labhost1.local --> 192.168.122.151
* labhost2.local --> 192.168.122.152
* labhost3.local --> 192.168.122.153

The inventory file contains the hostnames for each host, and have "gateway" and "gui" groups to assign special functionality to the hosts listed on each host.

Each host has a user called 'ansible' which uses the key in .ssh/id_fedora to login. This user can become a superuser without being prompted for a password. This is the user ansible will use to configure each host.

The install base is the Fedora 43 Workstation - but the boot target has been changed to multi-user.target so they do not boot into a graphical mode.

Temporarily each host has a "public" NIC and can be reached by ansible running on the hypervisor (this machine). The "public" network for the VMs is a NAT using the default network in libvirt (192.168.122.0/24). There's a "iso" network defined on libvirt which will be used for the isolation (non routable) network. This network has subnet 10.10.5.0/24.

To make static IP addresses, the default network setup uses MAC address mapping so while the host uses DHCP it will always get the same IP address. See above for the current mapping. 

The installer must do a basic configuration of each host before configuring networking to simplify:

* Add @core and @base packages
* Add performance and standard admin tools
* Enable cockpit and install pcp for monitoring
* Ensure tools like tcpdump, ifstat, nload, iftop and iperf3 mentioned in the presentation are installed
* Install dnsmasq and nginx on labhost1

# Lab architecture

Once the VMs are fully configured, here's the final architecture that must be implemented:

* All hosts must have a secondary network interface in the iso network
* labhost2 and labhost3 will have their current "public" network interface disabled in libvirt
* Configure dnsmasq on labhost1 as DNS and DHCP for labhost2 and labhost3. Add all 3 VMs to the DNSMASQ host configuration so they will resolve. Use ".isolated" as the domain name. Ensure that dnsmasq runs on labhost1 ONLY on the nic on ISO. 
* Configure labhost2 and labhost3 to use the DNS of labhost1 on the isolated network.
* Configure nginx on labhost1 to have a demo web page, and work as a proxy for labhost2 and labhost3. Make nginx listen on both the public and isolated network nics.

The public nic interface will below to the "public" firewalld zone "FedoraWorkstation" or "public". Remember to add sshd to the zone as an allowed service. 

## Isolation network

The isolated network will look like:

* labhost1.isolated --> 10.10.5.10
* labhost2.isolated --> 10.10.5.??
* labhost3.isolated --> 10.10.5.??

The IP addresses of labhost2.isolated and labhost3.isolated will come from dnsmasq on labhost1.isolated. It should use the dhcp range of 10.10.5.50-100. 

The NAT configured on labhost1 will allow for routing to external traffic. Please implement this but DISABLE the configuration so it can be enabled during the demonstration. The proxy can be configured and constantly running.

IP forward is not to be enabled on labhost1.

The interface for the isolated network need to use the "internal" firewalld zone.

## The NGINX website

The demo page should be very large fonts saying "Hello INTLUG". 
We'll only use port 80 for the demo. 

The firewall must add the http and proxy services to allow for access by the isolated hosts.

# What will be demonstrated

* Showing command line and GUI use of network configuration
    * Displaying network configuration
    * Changing network configuration
* Show testing/validation of network (ping, traceroute etc)
* Show testing of DNS
* Showing how to verify if ports are open without quering the firewall
* Showing that hosts that are "isolated" can use the gateway host to reach "outside the network"

and more ... there'll be Q&A and more examples may be needed