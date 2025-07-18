# G-PROJECT

```
  █████████             ███████████  ███████████      ███████         █████ ██████████  █████████  ███████████
 ███░░░░░███           ░░███░░░░░███░░███░░░░░███   ███░░░░░███      ░░███ ░░███░░░░░█ ███░░░░░███░█░░░███░░░█
░███    ░░░   ██████████░███    ░███ ░███    ░███  ███     ░░███      ░███  ░███  █ ░ ░███    ░░░ ░   ░███  ░ 
░███         ░░░░░░░░░░ ░██████████  ░██████████  ░███      ░███      ░███  ░██████   ░███            ░███   
░███   █████            ░███░░░░░░   ░███░░░░░███ ░███      ░███      ░███  ░███░░█   ░███            ░███   
░░███  ░░███            ░███         ░███    ░███ ░░███     ███ ░███   ███  ░███ ░   █░░███    ███    ░███   
 ░░█████████            █████        █████   █████ ░░░███████░  ░░█████░    ██████████ ░░█████████    █████   
  ░░░░░░░░░            ░░░░░        ░░░░░   ░░░░░    ░░░░░░░     ░░░░░    ░░░░░░░░░░   ░░░░░░░░░     ░░░░░   
```

## Installation

### Automatic Installation (Recommended)

**Basic installation:**
```bash
curl -fsSL https://raw.githubusercontent.com/festoinc/g-project/main/install.sh | bash
```

**Installation with Jira CLI integration:**
```bash
curl -fsSL https://raw.githubusercontent.com/festoinc/g-project/main/install-with-jira.sh | bash
```

Both installations will automatically:
- Install Node.js and Git (if needed)
- Install additional development tools (jq, curl, ripgrep)
- Download, build, and install G-PROJECT
- Add to your PATH
- Clean up temporary files

The Jira integration additionally:
- Installs go-jira CLI tool
- Configures Jira credentials (host, email, API token)
- Adds custom Jira helper functions:
  - `last-updates`: Shows issues updated since a specific time
  - `get-latest-changes`: Shows detailed changes for a specific issue

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

## Jira Integration Features

If you installed with Jira integration, you'll have access to these custom functions:

### last-updates
Shows all issues in a project updated since a specific time (UTC):
```bash
# Basic usage
last-updates PROJ '27-APR-2024 04:03:17'

# With debug logs
last-updates PROJ '27-APR-2024 04:03:17' --logs
```

### get-latest-changes
Shows detailed changes and comments for a specific issue since a given time (UTC):
```bash
# Basic usage
get-latest-changes AT-17 '14-JUL-2025 16:00:00'

# With debug logs
get-latest-changes AT-17 '14-JUL-2025 16:00:00' --logs
```

Both functions automatically handle timezone conversion between UTC input and your Jira server's timezone.
