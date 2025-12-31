# AI Coding Agent Instructions

## Project Overview
This is a networking project for INTLUG (International Linux User Group). It's purpose is to be a MARP based presentation on Linux networking topics, tools, and best practices.

## Development Setup
Enable the project environment to use MARP and use the Marp Previewer. A single file and a directory for images should be the main structure for the presentation. Use npm marp to build and preview the slides.

## Key Patterns & Conventions
Create a slide deck using MARP markdown syntax. Each slide should focus on a single topic or concept related to Linux networking. Use images from the designated images directory to enhance visual understanding. Start by definiting IPv4 networking paradigms and how the ISO model applies to Linux networking. Follow up with CLI for inspecting and managing network configurations on "Red Hat" based distroes, like Fedora.

## Common Tasks
Several Fedora VMs will be created to illustrate networking concepts. Tasks include:
- Setting up network interfaces (Network Manager CLI - nmcli)
- Configuring routing and firewall rules
- Demonstrating network troubleshooting commands
- Showcasing network performance monitoring tools

Use a simple nginx web server to demonstrate client-server interactions, load balancing, and reverse proxy setups.

Have an advanced section that covers setting up services like DNS, DHCP, and web servers on Fedora.

Networking will include dual homed VMs - where one of the IP interfaces are non-routable. One or more of the VMs will only be attached to the non-routable network to simulate isolated network environments, but still allow internet access via NAT on the routable interface. How to use a proxy-servers needs to be covered as well.

## Testing Strategy
All images and illustrations must work when copying the resulting HTML file to the system used to run the presentation. 

## Important Notes for AI Agents
- This is a new project - patterns and conventions will be established as development progresses
- Focus on Linux networking best practices and standards with a focus on Fedora. Have both CLI and GUI for basic networking tasks covered, and explain the advantages of using dbus based tools like Network Manager over traditional methods like editing /etc/sysconfig/network-scripts/ifcfg-*
- Cover how PolKit is used to manage permissions for networking tasks
- Ensure all networking configurations are compatible with Fedora's default firewall (firewalld)
- Consider security implications for all networking code
- Document all decisions and architectural choices for future reference

## Lab Environemnt

The demo environment is documented in [LAB-SETUP.md](LAB-SETUP.md).

Summary:
- 3 libvirt/kvm VMs running Fedora 43
- One VM will be dual homed. The other 2 VMs will only be attached to an isolated network
- One VM will run an nginx web server to demonstrate client-server interactions
- One VM acts as a NAT router between the isolated network and the internet
- One of the isolated VMs will have GNOME enabled to illustrate how to configure networking via GUI tools
- All VMs will have CLI tools to manage and inspect networking
- All VMs will have networking debugging tools installed
- All VMs will have cockpit with networking module enabled to illustrate web based management of networking

---

