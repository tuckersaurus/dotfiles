# dotfiles

Personal dotfiles and WSL development environment setup for Ubuntu 24.04 on WSL2.

**Repo:** https://github.com/tuckersaurus/dotfiles

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

Restart Windows, then:

```powershell
# Step 2: ensure WSL2 is the default before installing any distro
wsl --set-default-version 2
# Step 3: install Ubuntu 24.04
wsl --install -d Ubuntu-24.04
```

Alternatively, install Ubuntu 24.04 from the Microsoft Store after the restart.

#### Other Prerequisites

- Install [VS Code](https://code.visualstudio.com/) on Windows
- Install Google Chrome at the default path (`C:\Program Files\Google\Chrome\Application\chrome.exe`) — used by `wsl.sh` to set the `$BROWSER` variable and by `gh` for OAuth flows

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

Then run `wsl --shutdown` from PowerShell and reopen to apply.

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

**Option A — Copy existing keys from old machine via the Windows filesystem:**

```bash
# On the old machine — copy keys to a Windows path both machines can access:
cp ~/.ssh/id_ed25519 /mnt/c/Users/tuckersaurus/Desktop/
cp ~/.ssh/id_ed25519.pub /mnt/c/Users/tuckersaurus/Desktop/

# On the new machine — import from that path:
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cp /mnt/c/Users/tuckersaurus/Desktop/id_ed25519 ~/.ssh/
cp /mnt/c/Users/tuckersaurus/Desktop/id_ed25519.pub ~/.ssh/
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# Clean up the temporary copies from Windows:
rm /mnt/c/Users/tuckersaurus/Desktop/id_ed25519*
```

**Option B — Generate a new key:**

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "sheacox82@gmail.com"
```

Then add the new public key to GitHub: https://github.com/settings/keys

**Pre-populate GitHub's host key** to avoid the fingerprint prompt on first connect:

```bash
ssh-keyscan github.com >> ~/.ssh/known_hosts
```

**Switch the dotfiles remote from HTTPS to SSH:**

```bash
git -C ~/dotfiles remote set-url origin git@github.com:tuckersaurus/dotfiles.git
```

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

```bash
gh auth login
# Choose: GitHub.com → HTTPS → Login with a web browser
```

Set the browser to Chrome on Windows:

```bash
gh config set browser "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"
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
4. The dotfiles installer already symlinked `~/.claude/settings.json` and all custom commands — no further config needed

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
