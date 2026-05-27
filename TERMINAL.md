---

## Fresh terminal setup

SSH into a fresh Debian/Ubuntu box and run:

```bash
curl -fsSL https://raw.githubusercontent.com/lemonsaurus/lemonsaurus/main/terminal.sh | bash
```

This chains everything in the right order: prereqs, `bat`, `gh` CLI, interactive `gh auth` (SSH), [dotfiles](https://github.com/lemonsaurus/dotfiles), Claude Code, [agency](https://github.com/lemonsaurus/agency) + claudejail, and [dotagents](https://github.com/lemonsaurus/dotagents). Idempotent — safe to re-run if a step fails.
