# G-PROJECT Installation Guide

## Quick Installation (Recommended)

### One-liner Installation
```bash
curl -fsSL https://raw.githubusercontent.com/festoinc/g-project/main/install.sh | bash
```

Or if you prefer wget:
```bash
wget -qO- https://raw.githubusercontent.com/festoinc/g-project/main/install.sh | bash
```

This script will:
- ✅ Install Node.js (if not present)
- ✅ Install Git (if not present)
- ✅ Install additional development tools (jq, curl, ripgrep)
- ✅ Clone and build G-PROJECT
- ✅ Create executable symlink
- ✅ Add to PATH automatically
- ✅ Clean up temporary files

## What Gets Installed

### Core Dependencies
- **Node.js** - JavaScript runtime (LTS version)
- **Git** - Version control system
- **npm** - Package manager (comes with Node.js)

### Additional Tools
- **jq** - JSON processor for handling API responses
- **curl** - HTTP client for API calls
- **ripgrep (rg)** - Fast text search tool

### G-PROJECT Installation
- **Location**: `~/.g-project/`
- **Executable**: `~/.local/bin/g-project`
- **PATH**: Automatically added to your shell profile

## Manual Installation

If you prefer to install manually:

```bash
# 1. Clone the repository
git clone https://github.com/festoinc/g-project.git ~/.g-project

# 2. Navigate to directory
cd ~/.g-project

# 3. Install dependencies
npm install

# 4. Build the project
npm run build

# 5. Create symlink
mkdir -p ~/.local/bin
ln -sf ~/.g-project/packages/cli/dist/src/gemini.js ~/.local/bin/g-project
chmod +x ~/.local/bin/g-project

# 6. Add to PATH (add this to your ~/.bashrc or ~/.zshrc)
export PATH="$PATH:$HOME/.local/bin"
```

## Post-Installation

After installation, restart your terminal or run:
```bash
source ~/.bashrc  # or ~/.zshrc if using zsh
```

Verify installation:
```bash
g-project --help
```

## Getting Started

1. **Create a new project**:
   ```bash
   g-project /start-project <PROJECT_HANDLE> <JIRA_USER>
   ```

2. **Example**:
   ```bash
   g-project /start-project AT john.doe@company.com
   ```

This will create a `settings/settings.md` file with your project configuration.

## Troubleshooting

### Permission Issues
If you get permission errors, you may need to use sudo for system-wide tools:
```bash
curl -fsSL https://raw.githubusercontent.com/festoinc/g-project/main/install.sh | sudo bash
```

### PATH Issues
If `g-project` command is not found after installation:
```bash
echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bashrc
source ~/.bashrc
```

### Node.js Issues
If Node.js installation fails, install it manually:
```bash
# Using nvm (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install --lts
nvm use --lts

# Or using official installer
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
```

## Uninstallation

To remove G-PROJECT:
```bash
rm -rf ~/.g-project
rm ~/.local/bin/g-project
# Remove PATH export from your shell profile manually
```

## Update

To update G-PROJECT to the latest version:
```bash
curl -fsSL https://raw.githubusercontent.com/festoinc/g-project/main/install.sh | bash
```

The installer will automatically remove the old version and install the latest.

## Support

- 📚 **Documentation**: [GitHub Repository](https://github.com/festoinc/g-project)
- 🐛 **Issues**: [Report Issues](https://github.com/festoinc/g-project/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/festoinc/g-project/discussions)