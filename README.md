# Linux Networking Presentation - INTLUG

A comprehensive MARP-based presentation covering Linux networking fundamentals, focusing on Fedora systems.

## Topics Covered

- IPv4 Networking & OSI Model
- NetworkManager (CLI & GUI)
- Essential networking tools and commands
- firewalld configuration
- Routing, NAT, and dual-homed systems
- Proxy servers
- Service configuration (nginx, DNS, DHCP)

## Building the Presentation

### Prerequisites

Install Node.js and npm, then install dependencies:

```bash
npm install
```

### Build Commands

```bash
# Build HTML slides
npm run build

# Build PDF (requires Chrome/Chromium)
npm run build:pdf

# Build PowerPoint
npm run build:pptx

# Watch mode (auto-rebuild on changes)
npm run watch

# Preview in browser with live reload
npm run serve
```

### Manual Build

```bash
# HTML output
marp slides.md -o slides.html

# PDF output
marp slides.md -o slides.pdf --allow-local-files

# PowerPoint output
marp slides.md -o slides.pptx
```

## Presentation Structure

- **Part 1**: Networking Foundations (IPv4, OSI Model)
- **Part 2**: Network Configuration on Fedora (NetworkManager)
- **Part 3**: Essential Tools (ip, nmcli, monitoring)
- **Part 4**: Firewall Management (firewalld)
- **Part 5**: Advanced Topics (NAT, routing, proxies)
- **Part 6**: Service Configuration (nginx, DNS, DHCP)
- **Part 7**: Lab Environment Overview

## Images

Place supporting images in the `images/` directory. Reference them in slides using:

```markdown
![Description](images/your-image.png)
```

## Lab Environment

The presentation includes references to hands-on labs using Fedora VMs with:
- Dual-homed gateway systems
- Isolated internal networks
- NAT configuration
- Service deployments

## Contributing

This presentation is maintained by INTLUG. Suggestions and improvements are welcome!

## License

MIT License - See presentation for details.
