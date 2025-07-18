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

### Quick Installation (Recommended)

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

### Manual Installation

**Install from source:**
```bash
git clone https://github.com/festoinc/g-project.git ~/.g-project
cd ~/.g-project
npm install
npm run build
mkdir -p ~/.local/bin
ln -sf ~/.g-project/packages/cli/dist/src/gemini.js ~/.local/bin/g-project
chmod +x ~/.local/bin/g-project
export PATH="$PATH:$HOME/.local/bin"
```

Then run:
```bash
g-project --help
```

📖 **For detailed installation instructions, see [INSTALL.md](INSTALL.md)**
