# raidmonitor.sh

Lightweight monitor for Linux software-RAID (mdadm).

## Quick start (one-liner)

```bash
wget -qO- https://raw.githubusercontent.com/HyberHost/Scripts/main/linux/mdstat/raidmonitor.sh | bash
```

## Install dependencies

```bash
# Debian/Ubuntu
sudo apt-get install -y mdadm curl jq mailutils

# RHEL/CentOS
sudo yum install -y mdadm curl jq mailx
```

## Run locally

```bash
git clone https://github.com/HyberHost/Scripts.git
cd tools/linux/mdstat
./raidmonitor.sh
```

## Cron example

```
# m h dom mon dow command
*/5 * * * * /opt/scripts/raidmonitor.sh --output email --emailto raid@example.com
```

## Command-line options

| Option               | Default | Description                          |
|----------------------|---------|--------------------------------------|
| `--output`           | email   | email, slack, discord, none, or path to script |
| `--emailto`          | (cfg)   | Override email address for alerts     |
| `--critical`         | 1       | Number of failed arrays before alert  |
| `-v, --verbose`      | false   | Multi-line human output               |
| `-j, --json`         | false   | Single-line JSON output               |
| `-h, --help`         | —       | Show usage                            |

## Exit codes

0 = healthy, 1 = problem reported, 2 = usage error, 3 = runtime error

---

## Notes
- Alerts are sent via email using the `mail` command. Ensure it is installed and configured.
- For future outputs (slack, discord), use `--output ./slack.sh` or similar.
- All errors go to stderr. No secrets are printed.
- Script is self-contained and copy-paste friendly.
