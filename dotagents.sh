#!/usr/bin/env bash
#
# Public bootstrap for the (private) lemonsaurus/dotagents repo.
#
# Clones dotagents via SSH and hands off to its migrate.sh, which is
# idempotent (safe to re-run) and handles both fresh installs and
# upgrades from the old dotclaude layout.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/lemonsaurus/lemonsaurus/main/dotagents.sh | bash
#
# Requires:
# - git
# - SSH access to lemonsaurus/dotagents (the repo is private)
#
set -euo pipefail

REPO_URL="git@github.com:lemonsaurus/dotagents.git"
REPO_DIR="$HOME/git/lemonsaurus/dotagents"

if [ ! -d "$REPO_DIR/.git" ]; then
  echo ":: Cloning dotagents to $REPO_DIR"
  mkdir -p "$(dirname "$REPO_DIR")"
  if ! git clone "$REPO_URL" "$REPO_DIR"; then
    cat >&2 <<'EOF'
!! Clone failed.
   The dotagents repo is private. Make sure your SSH key is added to GitHub:
     gh auth setup-git
     ssh -T git@github.com
EOF
    exit 1
  fi
else
  echo ":: dotagents already at $REPO_DIR"
fi

exec "$REPO_DIR/migrate.sh"
