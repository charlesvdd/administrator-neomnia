# 🤖 **Neonia Administrator Toolkit**

> *Automated Linux onboarding scripts, proudly forged at **Neonia***

![Neonia Banner](https://placehold.co/1000x200?text=NEONIA+ADMINISTRATOR+TOOLKIT)

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Quick Start 🚀](#quick-start-)
4. [The `raw()` Helper Function](#the-raw-helper-function)
5. [Usage Examples](#usage-examples)
6. [Options](#options)
7. [How it Works 🔧](#how-it-works-)
8. [Contributing 🤝](#contributing-)
9. [License](#license)

---

## Overview

This repository centralises production‑ready Bash utilities for Ubuntu server administration. The flagship script, **`configure-group.sh`**, streamlines creation of Unix groups, sets POSIX ACLs, and brands every log line with a sprinkle of ✨ **Neonia** ✨.

> **Why?** Because typing the same `groupadd && chown && chmod && setfacl` incantation for the 100ᵉ time is so 2010.

---

## Features

| # | Capability                    | What it means for you                                                             |
| - | ----------------------------- | --------------------------------------------------------------------------------- |
| 1 | **Idempotent group handling** | Won’t crash if the group already exists.                                          |
| 2 | **Recursive directory ACLs**  | Future files inherit the right group & permissions.                               |
| 3 | **Fancy branding**            | All output lines are prefixed with `[Neonia]` & pretty emojis.                    |
| 4 | **Fully parametrised**        | Supply a *group*, *target directory* and *user* via flags—no interactive prompts. |
| 5 | **Fail‑fast, strict Bash**    | `set -euo pipefail` saves you from half‑configured servers.                       |

---

## Quick Start 🚀

> **Requirement:** `bash`, `curl` and `sudo` privileges.

```bash
# 1) Clone only this repo (classic way)
git clone --branch Groups https://github.com/charlesvdd/administrator-neomnia.git
cd administrator-neomnia

# 2) Run the script
sudo ./configure-group.sh -g devops -d /srv/shared -u "$USER"
```

**OR** go ultra‑minimal with the raw helper ↓

---

## The `raw()` Helper Function

Paste this one‑liner once and fetch any file straight from the **Groups** branch:

```bash
raw() {
  local f="$1"
  curl -sSL "https://raw.githubusercontent.com/charlesvdd/administrator-neomnia/Groups/$f" -o "$f" && \
  chmod +x "$f" && echo "[Neonia] ➜  $f ready!";
}
```

*Example — install and run `configure-group.sh` in two commands:*

```bash
raw configure-group.sh
sudo ./configure-group.sh -g data -d /data -u alice
```

---

## Usage Examples

```bash
# Create group “infra”, set permissions on /opt, add current user
sudo ./configure-group.sh -g infra

# Same, but custom dir & user
sudo ./configure-group.sh -g analytics -d /var/analytics -u bob
```

---

## Options

| Flag | Value    | Default      | Description                                          |
| ---- | -------- | ------------ | ---------------------------------------------------- |
| `-g` | *string* | —            | **(required)** Name of the Unix group to create/use. |
| `-d` | *path*   | `/opt`       | Directory on which to set ownership and ACLs.        |
| `-u` | *string* | current user | User to add to the group.                            |
| `-h` | —        | —            | Show inline help.                                    |

---

## How it Works 🔧

1. **Safety First** — `set -euo pipefail` turns on strict mode.
2. **Environment Check** — Verifies root privileges and the presence of `getent`, `groupadd`, `setfacl`.
3. **Idempotent Group Creation** — Uses `getent` to skip existing groups.
4. **Directory Setup** 

   * `chown -R root:<group>`
   * `chmod -R 2775` (sets *setgid* so children inherit the group)
   * `setfacl -d -m g:<group>:rwx` (default ACLs)
5. **User On‑boarding** — `usermod -aG <group> <user>`.
6. **Colourful Logging** — Consistent `[Neonia]` prefix, ANSI colours & emojis for each step.

---

## Contributing 🤝

1. Fork ➜ Create feature branch ➜ Commit ➜ Pull Request.
2. Keep shellcheck (`shellcheck *.sh`) score green.
3. Spell *Neonia* correctly 🧐.

---

## License

Distributed under the **MIT License**. See [`licence.txt`](./licence.txt) for details.

---

*Made with ❤️  &  ☕  by the Neonia team.*
