#!/bin/bash

# G-PROJECT Installation Script
# Usage: curl -fsSL https://raw.githubusercontent.com/festoinc/g-project/main/install.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/festoinc/g-project.git"
INSTALL_DIR="$HOME/.g-project"
BIN_DIR="$HOME/.local/bin"
TEMP_DIR="/tmp/g-project-install"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Node.js if not present
install_nodejs() {
    if ! command_exists node; then
        print_status "Node.js not found. Installing Node.js..."
        
        # Try to install Node.js using different methods
        if command_exists curl; then
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
        elif command_exists wget; then
            wget -qO- https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
        elif command_exists brew; then
            brew install node
        else
            print_error "Cannot install Node.js automatically. Please install Node.js manually and run this script again."
            exit 1
        fi
    else
        print_success "Node.js is already installed ($(node --version))"
    fi
}

# Function to install git if not present
install_git() {
    if ! command_exists git; then
        print_status "Git not found. Installing Git..."
        
        if command_exists apt-get; then
            sudo apt-get update && sudo apt-get install -y git
        elif command_exists yum; then
            sudo yum install -y git
        elif command_exists brew; then
            brew install git
        else
            print_error "Cannot install Git automatically. Please install Git manually and run this script again."
            exit 1
        fi
    else
        print_success "Git is already installed ($(git --version))"
    fi
}

# Function to install additional tools
install_additional_tools() {
    print_status "Installing additional development tools..."
    
    # Install jq for JSON processing
    if ! command_exists jq; then
        print_status "Installing jq..."
        if command_exists apt-get; then
            sudo apt-get install -y jq
        elif command_exists yum; then
            sudo yum install -y jq
        elif command_exists brew; then
            brew install jq
        else
            print_warning "Could not install jq automatically"
        fi
    else
        print_success "jq is already installed"
    fi
    
    # Install curl if not present
    if ! command_exists curl; then
        print_status "Installing curl..."
        if command_exists apt-get; then
            sudo apt-get install -y curl
        elif command_exists yum; then
            sudo yum install -y curl
        elif command_exists brew; then
            brew install curl
        else
            print_warning "Could not install curl automatically"
        fi
    else
        print_success "curl is already installed"
    fi
    
    # Install ripgrep for better searching
    if ! command_exists rg; then
        print_status "Installing ripgrep..."
        if command_exists apt-get; then
            sudo apt-get install -y ripgrep
        elif command_exists yum; then
            sudo yum install -y ripgrep
        elif command_exists brew; then
            brew install ripgrep
        else
            print_warning "Could not install ripgrep automatically"
        fi
    else
        print_success "ripgrep is already installed"
    fi
}

# Function to create necessary directories
create_directories() {
    print_status "Creating directories..."
    mkdir -p "$BIN_DIR"
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$TEMP_DIR"
}

# Function to add to PATH if not already there
add_to_path() {
    local shell_rc=""
    
    if [[ "$SHELL" == *"zsh"* ]]; then
        shell_rc="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        shell_rc="$HOME/.bashrc"
    else
        shell_rc="$HOME/.profile"
    fi
    
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        print_status "Adding $BIN_DIR to PATH in $shell_rc"
        echo "" >> "$shell_rc"
        echo "# Added by G-PROJECT installer" >> "$shell_rc"
        echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$shell_rc"
        export PATH="$PATH:$BIN_DIR"
    else
        print_success "$BIN_DIR is already in PATH"
    fi
}

# Function to install G-PROJECT
install_g_project() {
    print_status "Installing G-PROJECT..."
    
    # Remove existing installation
    if [ -d "$INSTALL_DIR" ]; then
        print_status "Removing existing installation..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # Clone repository
    print_status "Cloning G-PROJECT repository..."
    git clone "$REPO_URL" "$INSTALL_DIR"
    
    # Install dependencies and build
    cd "$INSTALL_DIR"
    print_status "Installing dependencies..."
    npm install
    
    print_status "Building G-PROJECT..."
    npm run build
    
    # Create executable wrapper script
    print_status "Creating executable wrapper..."
    cat > "$BIN_DIR/g-project" << 'EOF'
#!/bin/bash
exec node "$HOME/.g-project/packages/cli/dist/src/gemini.js" "$@"
EOF
    chmod +x "$BIN_DIR/g-project"
    
    # Clean up temp directory
    rm -rf "$TEMP_DIR"
}

# Function to verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    if [ -x "$BIN_DIR/g-project" ]; then
        print_success "G-PROJECT installed successfully!"
        print_status "You can now run: g-project"
        print_status "Or use: g-project --help"
    else
        print_error "Installation failed. Please check the errors above."
        exit 1
    fi
}

# Main installation function
main() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    G-PROJECT INSTALLER                       ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    print_status "Starting G-PROJECT installation..."
    
    # Check for required tools and install if missing
    install_git
    install_nodejs
    install_additional_tools
    
    # Create directories
    create_directories
    
    # Add to PATH
    add_to_path
    
    # Install G-PROJECT
    install_g_project
    
    # Verify installation
    verify_installation
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                   INSTALLATION COMPLETE!                     ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
    echo "2. Run: g-project --help"
    echo "3. Create a project: g-project /start-project <PROJECT_HANDLE> <JIRA_USER>"
    echo ""
    echo -e "${BLUE}Documentation:${NC} https://github.com/festoinc/g-project"
    echo -e "${BLUE}Issues:${NC} https://github.com/festoinc/g-project/issues"
}

# Run main function
main "$@"