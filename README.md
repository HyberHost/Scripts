
# HyberHost Scripts

Scripts for managing and monitoring Linux and Windows servers. Each script is self-contained, copy-paste friendly, and easy to deploy.

## Table of Contents
- [Overview](#overview)
- [Usage](#usage)
- [Folder Structure](#folder-structure)
- [Supported OSes](#supported-oses)
- [Contributing](#contributing)
- [Planning & Standards](#planning--standards)

## Overview
This repository contains scripts for:
- Monitoring RAID, disks, and VMs
- Automated notifications (Slack, Email)
- Routine server maintenance

## Usage
Clone the repo or copy individual scripts. See each script's readme.md for usage, dependencies, and cron examples.

## Folder Structure
Scripts are organized by OS and technology:

```
repo-root/
├── linux/
│   └── raid/
│       └── mdstat/
│           ├── mdstat.sh
│           └── readme.md
├── windows/
│   └── hyperv/
│       └── check-vms/
│           ├── check-vms.ps1
│           └── readme.md
├── planning.md
├── contributing.md
└── README.md
```

## Supported OSes
- Linux (Debian 12+, Ubuntu 22.04+, RHEL/CentOS 8+)
- Windows Server 2022+

## Contributing
See [contributing.md](contributing.md) for how to add or improve scripts.

## Planning & Standards
See [planning.md](planning.md) for required structure, config, and documentation standards.
