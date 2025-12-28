# planning.md

This document is written for any human or LLM who will add, review, or refactor scripts in this repository.  
Follow these rules **exactly** so every script remains 100 % self-contained and copy-paste friendly.

---

## 1. Folder layout

```
repo-root
├── linux
│   ├── raid
│   │   └── mdstat
│   │       ├── mdstat.sh          # executable
│   │       └── readme.md          # docs
│   └── …
├── windows
│   ├── hyperv
│   │   └── check-vms
│   │       ├── check-vms.ps1
│   │       └── readme.md
│   └── …
└── planning.md   # ← this file
```

- **One script = one directory**  
- Directory name = script name without extension  
- The only two mandatory files are the script and readme.md  
- Put extra helpers (systemd units, sample configs, etc.) inside the same directory if you really need them.

---

## 2. Script requirements

### 2.1 Shebang & interpreter
- Linux → `#!/usr/bin/env bash`  
- Windows → `#Requires -Version 5.1` (or higher) at the top of the `.ps1`

### 2.2 Configuration block
The first 25–40 lines must be an easily editable config block:

```bash
############################  USER CONFIG  ############################
SEND_TO="discord"           # discord | slack | email | none
DISCORD_WEBHOOK=""          # leave empty to disable
CRITICAL_THRESHOLD=1        # how many failed disks before alert
#####################################################################
```

Everything below that line must be able to run **unchanged** when the user
supplies the same values via arguments.

### 2.3 Argument override
Support long options only, no cryptic short flags.

```bash
./mdstat.sh \
  --output discord \
  --discord-webhook "https://discord.com/api/…" \
  --critical-threshold 2
```

If an argument is omitted, fall back to the value in the config block.

### 2.4 Exit codes
- `0` = OK  
- `1` = problem detected but already reported  
- `2` = usage / argument error  
- `3` = internal error (set -e triggered, etc.)

### 2.5 Output rules
- Normal mode → one concise line: `OK: md0, md1 healthy`  
- Verbose mode (`-v` or `--verbose`) → multi-line, human friendly  
- JSON mode (`-j` or `--json`) → single line, machine readable  
- All errors go to `stderr`  
- Never print secrets (webhook URLs, passwords)

---

## 3. readme.md template

Copy-paste skeleton for every new script directory:

````markdown
# mdstat.sh

Lightweight monitor for Linux software-RAID (mdadm).

## Quick start (one-liner)

```bash
wget -qO- https://raw.githubusercontent.com/HyberHost/Scripts/main/linux/raid/mdstat/mdstat.sh | bash
```

## Install dependencies

```bash
# Debian/Ubuntu
sudo apt-get install -y mdadm curl jq

# RHEL/CentOS
sudo yum install -y mdadm curl jq
```

## Run locally

```bash
git clone https://github.com/HyberHost/Scripts.git
cd linux/raid/mdstat
./mdstat.sh
```

## Cron example

```
# m h dom mon dow command
*/5 * * * * /opt/scripts/mdstat.sh --output discord --discord-webhook "https://discord.com/api/…"
```

## Command-line options

| Option               | Default | Description                          |
|----------------------|---------|--------------------------------------|
| `--output`           | none    | discord, slack, email, none         |
| `--discord-webhook`  | (cfg)   | Override Discord webhook URL        |
| `--critical`         | 1       | Number of failed disks before alert |
| `-v, --verbose`      | false   | Multi-line human output             |
| `-j, --json`         | false   | Single-line JSON output             |
| `-h, --help`         | —       | Show usage                          |

## Exit codes

0 = healthy, 1 = problem reported, 2 = usage error, 3 = runtime error
````

---

## 4. Cross-script conventions

- Always use `set -euo pipefail` (Bash) or `$ErrorActionPreference = 'Stop'` (PowerShell)  
- Never `cd` outside the script directory; work with absolute paths  
- Log to `/var/log/...` only when a `--logfile` switch is supplied  
- Provide `--dry-run` whenever the script **changes** something (mount, resize, restart, etc.)  
- Keep shebang lines at column 0, no blank lines before them  
- Use `curl -fsSL` or `Invoke-RestMethod` for downloads; never use `curl -k` or `--insecure`  
- Add `| head -c 1M` or similar when you `wget` a user-supplied URL to avoid blowing memory  
- If you must cache, place cache under `/tmp/__SCRIPTNAME__.cache` and `trap` removal on exit  
- Do **not** add colour codes unless `--color` is explicitly given  
- If you add colour, respect `NO_COLOR` environment variable

---


## 5. Deprecation & removal

- To deprecate a script, add a note at the top of its readme.md and open an issue for discussion.
- To remove a script, submit a PR that deletes the directory and updates any references in documentation.

## 6. Minimum readme.md standard

Each script's readme.md must include:
- One-liner description
- Quick start (one-liner)
- Dependency list
- Cron example
- Command-line options table
- Exit codes

---

## 7. Versioning & releases

- Repo uses **CalVer**: `YYYY.MM.DD.patch` (e.g. `2025.12.27.1`)  
- GitHub release must attach a zipped snapshot of the whole repo; users behind corporate proxies prefer ZIP over `git clone`  
- Tag must match folder name for every script touched in that release  
- Keep `main` branch always deployable; use PR + squash merge

---

## 8. TL;DR for LLMs

- One script lives alone in its own directory  
- Top editable config block + argument override  
- readme.md with dependencies, one-liner, cron sample, exit codes  
- Output short & clear; optional verbose or JSON  
- Bash or PowerShell only  
- Follow the checklist and you’re done