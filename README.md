# dotfiles

Personal dotfiles and WSL development environment setup for Ubuntu 24.04 on WSL2.

**Repo:** https://github.com/tuckersaurus/dotfiles

---

## Automated Setup with Claude Code

Claude Code can complete most of this guide for you. A few steps require manual action first because they happen before WSL exists or involve interactive auth flows that can't be automated.

**Do these manually:**

1. Complete **Step 1** (Windows Prerequisites) — WSL install, `.wslconfig`, Ubuntu distro, VS Code, Chrome, Defender exclusion
2. Complete **Step 2** (Create User) — first Ubuntu launch, create the `tuckersaurus` user

**Then open Claude Code** (VS Code → connect to WSL → Claude Code extension) and paste:

```
I've completed the Windows prerequisites and created the WSL user.
Follow the README at ~/dotfiles/README.md and complete the rest of the setup.
Pause when you need input from me.
```

Claude will pause for: SSH key passphrase, adding the public key to GitHub, `gh auth login` browser flow, and the token values for `~/.secrets`.

---

## New Machine Setup Guide

Follow these steps in order to go from a fresh Windows install to a fully configured development environment.

---

### 1. Windows Prerequisites

#### Enable WSL2 and Install Ubuntu

Run the following in PowerShell as Administrator:

```powershell
# Step 1: enable WSL (requires restart)
wsl --install --no-distribution
```

Restart Windows, then set WSL2 as default and create the resource limits config **before** installing the distro — `.wslconfig` is read on first launch:

```powershell
# Step 2: ensure WSL2 is the default before installing any distro
wsl --set-default-version 2
```

#### Configure WSL Resource Limits

Create `C:\Users\tuckersaurus\.wslconfig` to cap WSL memory and CPU usage. Open it in Notepad from PowerShell:

```powershell
notepad "$env:USERPROFILE\.wslconfig"
```

Paste the following and save:

```ini
[wsl2]
memory=6GB
processors=4
swap=2GB
```

Now install the distro — the resource limits will apply from first launch:

```powershell
# Step 3: install Ubuntu 24.04
wsl --install -d Ubuntu-24.04
```

Alternatively, install Ubuntu 24.04 from the Microsoft Store.

#### Other Prerequisites

- Install [VS Code](https://code.visualstudio.com/) on Windows
- Install Google Chrome at the default path (`C:\Program Files\Google\Chrome\Application\chrome.exe`) — used by `wsl.sh` to set the `$BROWSER` variable and by `gh` for OAuth flows

#### Add Windows Defender Exclusion

Defender scanning the WSL filesystem can cause significant slowdowns on large repos. Open PowerShell as Administrator:

```powershell
Add-MpPreference -ExclusionPath "$env:LOCALAPPDATA\Packages\CanonicalGroupLimited.Ubuntu_79rhkp1fndgsc"
```

> The folder name includes a store ID suffix that may differ slightly. Verify with `ls $env:LOCALAPPDATA\Packages\Canonical*` and use the matching path.

---

### 2. Create User

On first launch, Ubuntu runs a setup wizard. Create the user `tuckersaurus` and set a password when prompted. Confirm sudo works:

```bash
sudo apt update
```

---

### 3. Configure WSL

With the user created, write `/etc/wsl.conf` to enable systemd and lock the default user:

```bash
sudo tee /etc/wsl.conf > /dev/null << 'EOF'
[boot]
systemd=true

[user]
default=tuckersaurus
EOF
```

Then restart WSL from PowerShell: `wsl --shutdown`, reopen.

---

### 4. System Packages

#### Base Tools

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
  curl wget git git-lfs \
  build-essential \
  gnupg ca-certificates \
  unzip zip \
  openssh-client
git lfs install
```

#### GitHub CLI

```bash
(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y))
sudo mkdir -p -m 755 /etc/apt/keyrings
wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install gh -y
```

#### Docker

```bash
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update && sudo apt install -y \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
```

Then either run `newgrp docker` (starts a new subshell with the group active) or close and reopen the terminal to pick up the new group membership.

#### Passwordless Docker Service Start

`wsl.sh` auto-starts the Docker service on every shell open. Create a sudoers entry so it runs without a password prompt:

```bash
echo "tuckersaurus ALL=(ALL) NOPASSWD: /usr/sbin/service docker start" \
  | sudo tee /etc/sudoers.d/docker-start
sudo chmod 440 /etc/sudoers.d/docker-start
```

---

### 5. Dotfiles

Clone via HTTPS for now — SSH keys aren't set up yet. The remote will be switched to SSH in Step 7.

```bash
git clone https://github.com/tuckersaurus/dotfiles.git ~/dotfiles
```

Prepare the `~/.claude` directory (the installer symlinks into it):

```bash
mkdir -p ~/.claude/commands
```

Run the installer:

```bash
cd ~/dotfiles && ./install.sh
source ~/.bashrc
```

The installer does the following:
- Symlinks `~/.gitconfig` → `~/dotfiles/.gitconfig`
- Symlinks `~/.gitignore_global` → `~/dotfiles/.gitignore_global`
- Symlinks `~/.claude/CLAUDE.md`, `settings.json`, and all `commands/*.md`
- Injects the dotfiles source block into `~/.bashrc`
- Installs `cookiecutter` via pip
- Adds `~/dotfiles/scripts/` to `PATH`, providing `git-consolidate` and `git-delete` helper scripts

> **.NET** is devcontainer-only — do not install it at the WSL level.

---

### 6. Project Directory Structure

```bash
mkdir -p ~/projects/source/{local,github}
```

Create the VS Code workspace file at `~/tuckersaurus.code-workspace`:

```bash
cat > ~/tuckersaurus.code-workspace << 'EOF'
{
  "folders": [
    { "path": "projects" },
    { "path": "dotfiles" }
  ],
  "settings": {
    "files.exclude": {
      "**/node_modules": true
    }
  }
}
EOF
```

---

### 7. SSH Keys

Each machine gets its own SSH key. Generate a new one — don't copy keys from another machine. If a machine is decommissioned, revoke its key from all services without affecting others.

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "sheacox82@gmail.com" -a 100
```

**Use a passphrase when prompted** — it protects the key if the machine is compromised. The SSH agent setup below means you only enter it once per Windows restart.

`-a 100` uses 100 KDF rounds, making passphrase brute-force significantly harder.

Print the public key to register on services:

```bash
cat ~/.ssh/id_ed25519.pub
```

Add it to every SSH-based service this machine needs access to — one key, all targets:
- **GitHub:** https://github.com/settings/keys (New SSH key → Authentication Key)
- Any other hosts (VPS, other SSH servers, etc.)

**Pre-populate GitHub's host key** to avoid the fingerprint prompt on first connect:

```bash
ssh-keyscan github.com >> ~/.ssh/known_hosts
```

**Switch the dotfiles remote from HTTPS to SSH:**

```bash
git -C ~/dotfiles remote set-url origin git@github.com:tuckersaurus/dotfiles.git
```

**SSH agent** — Without an agent, every `git push` prompts for the passphrase. Install `keychain` to persist the agent across terminal sessions — you'll only enter the passphrase once per Windows restart:

```bash
sudo apt install -y keychain
```

`~/dotfiles/bash/ssh.sh` handles agent init automatically on every shell open. Open a new terminal now — you'll be prompted for your passphrase once to start the agent. All subsequent terminals will reuse it until the next Windows restart.

---

### 8. Secrets File

Create `~/.secrets` using a text editor. Avoid heredocs for secrets — they leak tokens to shell history.

```bash
nano ~/.secrets
```

Add the following, substituting your real tokens. Create a **machine-named token on GitHub for each** (e.g. `wsl-nuget-laptop01`) so individual machines can be revoked independently.

```bash
# GitHub PAT — scope: read:packages
# Used by NuGet for GitHub Packages restore
export GITHUB_NUGET_TOKEN="..."

# GitHub PAT — scopes: repo, read:org
# Used by the GitHub MCP server in Claude Code
export GITHUB_MCP_TOKEN="..."
```

Save and exit (`Ctrl+O`, `Ctrl+X`), then load the secrets:

```bash
source ~/.secrets
```

---

### 9. GitHub CLI Authentication

Set the browser first so the auth flow opens in Chrome:

```bash
gh config set browser "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"
gh auth login
# Choose: GitHub.com → HTTPS → Login with a web browser
```

---

### 10. Node.js (via NVM)

Check https://github.com/nvm-sh/nvm/releases for the latest release tag, then:

```bash
# Replace vX.Y.Z with the latest release tag
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/vX.Y.Z/install.sh | bash
source ~/.bashrc
nvm install --lts
nvm alias default node
```

NVM's installer appends its init block to `~/.bashrc`:

```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
```

Since dotfiles already sources all `bash/*.sh` files (including `bash/node.sh`), remove those three lines from `~/.bashrc` to avoid double-initialization.

---

### 11. VS Code & Claude Code

1. Open VS Code from WSL: `code .`
2. Install the **WSL extension** if not already present
3. Install the **Claude Code extension** from the VS Code marketplace
4. Configure the **dotfiles feature** so VS Code automatically runs `install.sh` in every new devcontainer. Open VS Code Settings (`Ctrl+,`), search for `dotfiles`, and set:
   - **Dotfiles: Repository** → `https://github.com/tuckersaurus/dotfiles`
   - **Dotfiles: Install Command** → `~/dotfiles/install.sh`

   Or add directly to VS Code's `settings.json` (`Ctrl+Shift+P` → "Open User Settings JSON"):
   ```json
   "dotfiles.repository": "https://github.com/tuckersaurus/dotfiles",
   "dotfiles.installCommand": "~/dotfiles/install.sh"
   ```

   This ensures MCP server configs, Claude settings, and custom commands are available in all devcontainers.

---

### 12. GPG Keys (optional — for signed commits)

Transfer via the Windows filesystem:

```bash
# On the old machine — export to Windows Desktop:
gpg --export-secret-keys YOUR_KEY_ID > /mnt/c/Users/tuckersaurus/Desktop/gpg-private.key

# On the new machine — import, set trust, then clean up:
gpg --import /mnt/c/Users/tuckersaurus/Desktop/gpg-private.key
gpg --edit-key YOUR_KEY_ID trust quit
# Enter 5 (ultimate) when prompted
rm /mnt/c/Users/tuckersaurus/Desktop/gpg-private.key
```

To configure git to sign commits, add to `~/.gitconfig`:

```ini
[commit]
    gpgsign = true
[user]
    signingkey = YOUR_KEY_ID
```

---

### 13. Verification Checklist

Run through this checklist after completing all steps:

```bash
# Git config symlink
ls -la ~/.gitconfig                               # should point to ~/dotfiles/.gitconfig

# GitHub CLI
gh auth status                                    # should show logged in

# SSH auth
ssh -T git@github.com                             # expect: Hi tuckersaurus!

# Docker (no sudo required)
docker run hello-world

# Dotfiles symlinks
ls -la ~/.gitconfig ~/.claude/CLAUDE.md ~/.claude/settings.json

# PATH includes dotfiles scripts
echo $PATH | grep dotfiles

# cookiecutter
cookiecutter --version

# Node
node --version && npm --version

# Secrets
echo $GITHUB_NUGET_TOKEN                          # should print the token value
echo $GITHUB_MCP_TOKEN                            # should print the token value

# MCP servers (open Claude Code and run)
# /mcp    — should list: github, fetch (global); postgres (workspace devcontainers only)
```
