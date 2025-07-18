# G-PROJECT

```
  █████████             ███████████  ███████████      ███████         █████ ██████████  █████████  ███████████
 ███░░░░░███           ░░███░░░░░███░░███░░░░░███   ███░░░░░███      ░░███ ░░███░░░░░█ ███░░░░░███░█░░░███░░░█
░███    ░░░   ██████████░███    ░███ ░███    ░███  ███     ░░███      ░███  ░███  █ ░ ░███    ░░░  ░   ░███  ░
░███         ░░░░░░░░░░ ░██████████  ░██████████  ░███      ░███      ░███  ░██████   ░███              ░███
░███    █████           ░███░░░░░░   ░███░░░░░███ ░███      ░███      ░███  ░███░░█   ░███              ░███
░░███  ░░███            ░███         ░███    ░███ ░░███     ███ ░███   ███  ░███ ░   █░░███    ███      ░███
 ░░█████████            █████        █████   █████ ░░░███████░  ░░█████░    ██████████ ░░█████████      █████
  ░░░░░░░░░            ░░░░░        ░░░░░   ░░░░░    ░░░░░░░     ░░░░░    ░░░░░░░░░░   ░░░░░░░░░      ░░░░░
```

## Installation

### Automatic Installation (Recommended)

**One-liner installation:**
```bash
curl -fsSL https://raw.githubusercontent.com/festoinc/g-project/main/install.sh | bash
```

This will automatically:
- Install Node.js and Git (if needed)
- Install additional development tools (jq, curl, ripgrep)
- Download, build, and install G-PROJECT
- Add to your PATH
- Clean up temporary files

After installation, restart your terminal or run:
```bash
source ~/.bashrc  # or ~/.zshrc
g-project --help
```

## Uninstallation

**One-liner uninstallation:**
```bash
curl -fsSL https://raw.githubusercontent.com/festoinc/g-project/main/uninstall.sh | bash
```

This will remove:
- G-PROJECT installation directory (`~/.g-project`)
- G-PROJECT executable (`~/.local/bin/g-project`)
- PATH entries from shell configuration files

**Note:** Node.js, Git, and other development tools will NOT be removed.
