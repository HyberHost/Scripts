# contributing.md

This file explains how to add a new script, improve an existing one, and open a pull-request that gets merged quickly.

---

## 1. Before you start

1. Read **planning.md** in the repo root – every rule there is mandatory.  
2. Open an issue first if your change is large (new directory, new OS support, etc.).  
3. Fork the repository **and** create a feature branch (`git checkout -b feat/linux/luks-monitor`).  
   Branch names must match the pattern `<type>/<os>/<short-name>`  
   - type = feat | fix | docs  
   - os = linux | windows | misc  

---

## 2. Quick scaffold (copy-paste)

From the repo root run:

```bash
# Linux example
./tools/scaffold.sh linux/btrfs/scrub
# Windows example
./tools/scaffold.ps1 windows/hyperv/check-vms
```

The helper creates:

```
os/technology/name/
├── name.sh or name.ps1   # executable, shebang, config block, arg parser
├── readme.md             # filled template
└── .gitkeep
```

Edit only those two files; everything else is optional.

---

## 3. Script checklist (copy into PR description)

```
- [ ] shellcheck / PSScriptAnalyzer clean
- [ ] `./name.sh --help` exits 2 with usage text
- [ ] `./name.sh --json | jq .` valid JSON
- [ ] `./name.sh --dry-run` touches nothing
- [ ] readme.md contains one-liner, dependencies, cron sample
- [ ] No hard-coded usernames or paths
- [ ] Tested on Ubuntu 24.04 / Windows Server 2022 (or mention OS tested)
```


All checklist items must be completed before merge. Automated commit testing is not currently enforced; reviewers will verify items manually.

---

## 4. Commit style

We follow **Conventional Commits** (automated changelog).

```
feat(linux/btrfs/scrub): add monitor for stale scrubs
fix(windows/hyperv/check-vms): correct VM count on clustered hosts
docs: update contributing.md with commit examples
```

Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`.  
Scope must match the directory you touched.

---


## 5. Pull-request template

When opening a pull request, use the template in [PULL_REQUEST_TEMPLATE.md](PULL_REQUEST_TEMPLATE.md) and fill in each section as described.

---

## 6. Review & merge


1. A maintainer will review your PR and may test the one-liner in a fresh container/VM.
2. After approvals, the PR is squash-merged to `main`.
3. A GitHub release (CalVer) is created if any script directory changed.

---

## 7. Release notes for contributors

- Releases are **immutable**; never force-push to `main`.  
- If you need to fix a typo in an already-released script, open a new PR.  
- The zipped snapshot attached to each release is produced by CI; do **not** commit ZIPs.

---


## 8. Code review & style guide

- Reviews are typically completed within 3 business days.
- Follow the style of existing scripts (Bash: 2-space indent, PowerShell: 4-space indent).
- Use clear variable names and add comments for non-obvious logic.
- For questions, open a GitHub Discussion, join #scripts on Discord (invite in README), or email scripts@hyberhost.com.

---

## 9. Code of conduct

Be polite, be precise, keep diffs small.  
We release infrastructure code; sloppy PRs can break thousands of servers.

---

That’s it—fork, branch, scaffold, check, push, PR, and we’ll merge fast.