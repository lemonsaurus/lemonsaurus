#!/usr/bin/env bash
#
# Complete terminal setup for a fresh Debian/Ubuntu box.
#
# Installs, in order:
#   1. apt prerequisites (curl, git, build tools)
#   2. bat (from GitHub release .deb — apt's version is too old on most boxes)
#   3. gh CLI (GitHub's official apt repo)
#   4. gh auth login (interactive — sets up SSH key for private repos)
#   5. dotfiles  (zsh, starship, eza, plugins, configs)
#   6. Claude Code
#   7. agency + claudejail (with bubblewrap)
#   8. dotagents
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/lemonsaurus/lemonsaurus/main/terminal.sh | bash
#
# Each step is idempotent — safe to re-run after fixing a failure.

set -euo pipefail

bold="\033[1m"; cyan="\033[36m"; green="\033[32m"; yellow="\033[33m"; red="\033[31m"; reset="\033[0m"
step() { printf "\n${bold}${cyan}==> [%d/8] %s${reset}\n" "$1" "$2"; }
ok()   { printf "${bold}${green}  ✓${reset} %s\n" "$*"; }
warn() { printf "${bold}${yellow}  !${reset} %s\n" "$*"; }
fail() { printf "${bold}${red}  ✗${reset} %s\n" "$*" >&2; exit 1; }

[ "$(uname -s)" = "Linux" ] || fail "This script is Debian/Ubuntu only."
command -v apt-get >/dev/null || fail "apt-get not found — this script is Debian/Ubuntu only."

ARCH="$(dpkg --print-architecture)"  # amd64 / arm64

# ── 1. apt prerequisites ────────────────────────────────────────────────────
step 1 "apt prerequisites"
sudo apt-get update -y
sudo apt-get install -y curl git ca-certificates wget build-essential
ok "prerequisites installed"

# ── 2. bat (from GitHub release; apt versions on older Ubuntu are too old) ──
step 2 "bat"
if command -v bat >/dev/null || command -v batcat >/dev/null; then
    ok "bat already installed"
else
    BAT_VERSION="0.24.0"
    TMP_DEB="$(mktemp --suffix=.deb)"
    curl -fsSL "https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat_${BAT_VERSION}_${ARCH}.deb" -o "$TMP_DEB"
    sudo dpkg -i "$TMP_DEB"
    rm -f "$TMP_DEB"
    ok "bat ${BAT_VERSION} installed"
fi

# ── 3. gh CLI ───────────────────────────────────────────────────────────────
step 3 "gh CLI"
if command -v gh >/dev/null; then
    ok "gh already installed"
else
    # https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian
    sudo mkdir -p -m 755 /etc/apt/keyrings
    out=$(mktemp)
    wget -nv -O"$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg
    cat "$out" | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    rm -f "$out"
    echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt-get update -y
    sudo apt-get install -y gh
    ok "gh installed"
fi

# ── 4. gh auth login (interactive) ──────────────────────────────────────────
step 4 "GitHub auth"
if gh auth status >/dev/null 2>&1; then
    ok "gh already authenticated"
else
    warn "Choose SSH when prompted — this generates and uploads an SSH key for private repos (dotagents)."
    # < /dev/tty so this works under curl | bash
    gh auth login -p ssh -h github.com -w < /dev/tty
    ok "gh authenticated"
fi

# Make sure SSH works for git, in case the user picked HTTPS or already had partial auth
if ! ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    warn "SSH to github.com isn't working yet — running gh auth setup-git and retrying"
    gh auth setup-git || true
fi

# ── 5. dotfiles ─────────────────────────────────────────────────────────────
step 5 "dotfiles"
curl -fsSL "https://raw.githubusercontent.com/lemonsaurus/dotfiles/main/setup.sh?$(date +%s)" | bash
ok "dotfiles installed"

# ── 6. Claude Code ──────────────────────────────────────────────────────────
step 6 "Claude Code"
if command -v claude >/dev/null; then
    ok "claude already installed"
else
    curl -fsSL https://claude.ai/install.sh | bash
    ok "Claude Code installed"
fi

# ── 7. agency + claudejail ──────────────────────────────────────────────────
step 7 "agency + claudejail"
AGENCY_DIR="$HOME/git/lemonsaurus/agency"
if [ ! -d "$AGENCY_DIR/.git" ]; then
    mkdir -p "$(dirname "$AGENCY_DIR")"
    git clone https://github.com/lemonsaurus/agency.git "$AGENCY_DIR"
fi
REPO_DIR="$AGENCY_DIR" bash "$AGENCY_DIR/install.sh"

sudo apt-get install -y bubblewrap
make -C "$AGENCY_DIR" install-claudejail
ok "agency + claudejail installed"

# ── 8. dotagents ────────────────────────────────────────────────────────────
step 8 "dotagents"
curl -fsSL https://raw.githubusercontent.com/lemonsaurus/lemonsaurus/main/dotagents.sh | bash
ok "dotagents installed"

printf "\n${bold}${green}All done.${reset} Restart your shell (or run ${bold}zsh${reset}) to pick up the new environment.\n"
