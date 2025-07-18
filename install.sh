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
JIRA_FUNCTIONS_FILE="$HOME/.jira_functions"

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

# Function to install go-jira
install_go_jira() {
    if ! command_exists jira; then
        print_status "Installing go-jira CLI..."
        
        # Check the operating system and architecture
        local OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
        local ARCH="$(uname -m)"
        
        # Map architecture names for go-jira format
        # Note: go-jira only provides amd64 builds for macOS, ARM64 Macs will use amd64 via Rosetta
        case "$ARCH" in
            x86_64)
                ARCH="amd64"
                ;;
            i386|i686)
                ARCH="386"
                ;;
            aarch64|arm64)
                if [ "$OS" = "darwin" ]; then
                    print_status "Using Intel binary for ARM64 Mac (runs via Rosetta)"
                    ARCH="amd64"
                else
                    print_error "ARM64 Linux not supported by go-jira. Only amd64 available."
                    exit 1
                fi
                ;;
            *)
                print_error "Unsupported architecture: $ARCH"
                exit 1
                ;;
        esac
        
        # Map OS names for go-jira format
        case "$OS" in
            darwin)
                OS="darwin"
                ;;
            linux)
                OS="linux"
                ;;
            mingw*|msys*|cygwin*)
                OS="windows"
                ;;
            *)
                print_error "Unsupported operating system: $OS"
                exit 1
                ;;
        esac
        
        # Get the latest release version
        print_status "Getting latest go-jira release..."
        local VERSION
        if command_exists curl; then
            VERSION=$(curl -s https://api.github.com/repos/go-jira/jira/releases/latest | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
        elif command_exists wget; then
            VERSION=$(wget -qO- https://api.github.com/repos/go-jira/jira/releases/latest | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
        else
            print_error "Neither curl nor wget found. Cannot get latest version."
            exit 1
        fi
        
        if [ -z "$VERSION" ]; then
            print_warning "Could not determine latest go-jira version from GitHub API"
            print_status "Using fallback version v1.0.27"
            VERSION="v1.0.27"
        fi
        
        print_status "Found go-jira version: $VERSION"
        
        # Download the release
        print_status "Downloading go-jira $VERSION for $OS/$ARCH..."
        local FILENAME="jira-${OS}-${ARCH}"
        if [ "$OS" = "windows" ]; then
            FILENAME="${FILENAME}.exe"
        fi
        local DOWNLOAD_URL="https://github.com/go-jira/jira/releases/download/${VERSION}/${FILENAME}"
        
        print_status "Download URL: $DOWNLOAD_URL"
        
        # Ensure temp directory exists
        mkdir -p "$TEMP_DIR"
        
        if command_exists curl; then
            if ! curl -fsSL "$DOWNLOAD_URL" -o "$TEMP_DIR/jira"; then
                print_error "Download failed from $DOWNLOAD_URL"
                print_error "This may be due to:"
                print_error "1. Network connectivity issues"
                print_error "2. GitHub rate limiting"
                print_error "3. The binary doesn't exist for your platform"
                exit 1
            fi
        elif command_exists wget; then
            if ! wget -qO "$TEMP_DIR/jira" "$DOWNLOAD_URL"; then
                print_error "Download failed from $DOWNLOAD_URL"
                print_error "This may be due to:"
                print_error "1. Network connectivity issues"
                print_error "2. GitHub rate limiting"
                print_error "3. The binary doesn't exist for your platform"
                exit 1
            fi
        fi
        
        # Check if the downloaded file exists and has content
        if [ ! -f "$TEMP_DIR/jira" ] || [ ! -s "$TEMP_DIR/jira" ]; then
            print_error "Downloaded file is empty or missing"
            exit 1
        fi
        
        # Make it executable and move to bin directory
        chmod +x "$TEMP_DIR/jira"
        mkdir -p "$BIN_DIR"
        mv "$TEMP_DIR/jira" "$BIN_DIR/jira"
        
        print_success "go-jira $VERSION installed successfully"
    else
        print_success "go-jira is already installed ($(jira version 2>/dev/null || echo 'version unknown'))"
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

# Function to add Jira functions
add_jira_functions() {
    print_status "Adding custom Jira functions..."
    
    cat > "$JIRA_FUNCTIONS_FILE" << 'EOF'
# Enhanced last-updates function with --logs flag
last-updates() {
    local show_logs=false
    local project=""
    local input_date=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --logs)
                show_logs=true
                shift
                ;;
            *)
                if [ -z "$project" ]; then
                    project="$1"
                elif [ -z "$input_date" ]; then
                    input_date="$1"
                else
                    echo "Error: Too many arguments"
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    if [ -z "$project" ] || [ -z "$input_date" ]; then
        echo "Usage: last-updates PROJECT_KEY 'DD-MMM-YYYY HH:MM:SS' [--logs]"
        echo "Example: last-updates PROJ '27-APR-2024 04:03:17'"
        echo "Example: last-updates PROJ '27-APR-2024 04:03:17' --logs"
        echo "Note: Input time is assumed to be UTC"
        echo "      --logs flag shows detailed processing steps"
        return 1
    fi
    
    if [ "$show_logs" = true ]; then
        echo "Getting Jira server timezone..."
    fi
    
    # Get Jira server time to extract timezone offset
    local server_info=$(jira request /rest/api/2/serverInfo)
    local server_time=$(echo "$server_info" | grep -o '"serverTime"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)".*/\1/')
    
    # Extract timezone offset from serverTime (e.g., +0300)
    local timezone_offset=$(echo "$server_time" | grep -o '[+-][0-9][0-9][0-9][0-9]')
    
    if [ -z "$timezone_offset" ]; then
        echo "Error: Could not detect Jira timezone offset"
        return 1
    fi
    
    if [ "$show_logs" = true ]; then
        echo "Jira server time: $server_time"
        echo "Jira timezone offset: $timezone_offset"
    fi
    
    # Convert UTC input to Jira server time by adding/subtracting offset
    local hours=${timezone_offset:1:2}
    local minutes=${timezone_offset:3:2}
    local sign=${timezone_offset:0:1}
    
    # Calculate total minutes offset
    local total_minutes=$((hours * 60 + minutes))
    
    local jira_date
    if [ "$sign" = "+" ]; then
        # Jira is ahead of UTC, add the offset
        jira_date=$(date -u -d "$input_date UTC +$total_minutes minutes" +"%Y-%m-%d %H:%M")
    else
        # Jira is behind UTC, subtract the offset  
        jira_date=$(date -u -d "$input_date UTC -$total_minutes minutes" +"%Y-%m-%d %H:%M")
    fi
    
    if [ $? -ne 0 ]; then
        echo "Error: Invalid date format. Use 'DD-MMM-YYYY HH:MM:SS'"
        return 1
    fi
    
    if [ "$show_logs" = true ]; then
        echo "Input UTC time: $input_date"
        echo "Converted to Jira time (UTC$timezone_offset): $jira_date"
        echo "JQL: project = '$project' AND updated >= '$jira_date'"
        echo ""
    fi
    
    jira list --query="project = '$project' AND updated >= '$jira_date'"
}

# Fixed get-latest-changes function with proper argument handling
get-latest-changes() {
    local show_logs=false
    local issue_key=""
    local input_date=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --logs)
                show_logs=true
                shift
                ;;
            *)
                if [ -z "$issue_key" ]; then
                    issue_key="$1"
                elif [ -z "$input_date" ]; then
                    input_date="$1"
                else
                    echo "Error: Too many arguments"
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    if [ -z "$issue_key" ] || [ -z "$input_date" ]; then
        echo "Usage: get-latest-changes ISSUE_KEY 'DD-MMM-YYYY HH:MM:SS' [--logs]"
        echo "Example: get-latest-changes AT-17 '14-JUL-2025 16:00:00'"
        echo "Example: get-latest-changes AT-17 '14-JUL-2025 16:00:00' --logs"
        echo "Note: Input time is assumed to be UTC"
        echo "      --logs flag shows detailed processing steps"
        return 1
    fi
    
    if [ "$show_logs" = true ]; then
        echo "Getting Jira server timezone..."
    fi
    
    # Get Jira server time to extract timezone offset
    local server_info=$(jira request /rest/api/2/serverInfo)
    local server_time=$(echo "$server_info" | grep -o '"serverTime"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)".*/\1/')
    
    # Extract timezone offset from serverTime (e.g., +0300)
    local timezone_offset=$(echo "$server_time" | grep -o '[+-][0-9][0-9][0-9][0-9]')
    
    if [ -z "$timezone_offset" ]; then
        echo "Error: Could not detect Jira timezone offset"
        return 1
    fi
    
    if [ "$show_logs" = true ]; then
        echo "Jira timezone offset: $timezone_offset"
    fi
    
    # Convert UTC input to Jira server time by adding/subtracting offset
    local hours=${timezone_offset:1:2}
    local minutes=${timezone_offset:3:2}
    local sign=${timezone_offset:0:1}
    
    # Calculate total minutes offset
    local total_minutes=$((hours * 60 + minutes))
    
    local jira_date
    if [ "$sign" = "+" ]; then
        # Jira is ahead of UTC, add the offset
        jira_date=$(date -u -d "$input_date UTC +$total_minutes minutes" +"%Y-%m-%dT%H:%M:%S$timezone_offset")
    else
        # Jira is behind UTC, subtract the offset  
        jira_date=$(date -u -d "$input_date UTC -$total_minutes minutes" +"%Y-%m-%dT%H:%M:%S$timezone_offset")
    fi
    
    if [ $? -ne 0 ]; then
        echo "Error: Invalid date format. Use 'DD-MMM-YYYY HH:MM:SS'"
        return 1
    fi
    
    if [ "$show_logs" = true ]; then
        echo "Input UTC time: $input_date"
        echo "Converted to Jira time: $jira_date"
        echo "Getting changes for issue $issue_key since $jira_date..."
        echo ""
    fi
    
    echo "=== CHANGES FOR $issue_key SINCE $jira_date ==="
    echo ""
    
    # Parse and display changelog entries
    jira request "/rest/api/2/issue/$issue_key?expand=changelog" | jq -r --arg since_date "$jira_date" '
        .changelog.histories[] | 
        select(.created >= $since_date) |
        "CHANGE: " + .created + " by " + .author.displayName + 
        (.items[] | "\n  • " + .field + ": " + 
         (if .fromString then "\"" + .fromString + "\"" else "null" end) + 
         " → " + 
         (if .toString then "\"" + .toString + "\"" else "null" end)) + "\n"
    '
    
    echo "=== COMMENTS SINCE $jira_date ==="
    echo ""
    
    # Also get comments since the date  
    jira request "/rest/api/2/issue/$issue_key?expand=changelog" | jq -r --arg since_date "$jira_date" '
        .fields.comment.comments[]? |
        select(.created >= $since_date) |
        "COMMENT: " + .created + " by " + .author.displayName + "\n" +
        "  " + .body + "\n"
    '
}
EOF
    
    print_success "Custom Jira functions added to $JIRA_FUNCTIONS_FILE"
}

# Function to update shell RC files
update_shell_rc() {
    local shell_files=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")
    local updated=false
    
    for shell_file in "${shell_files[@]}"; do
        if [ -f "$shell_file" ]; then
            # Check if the source line already exists
            if ! grep -q "source.*\.jira_functions" "$shell_file"; then
                print_status "Adding jira_functions to $shell_file..."
                echo "" >> "$shell_file"
                echo "# Source Jira custom functions" >> "$shell_file"
                echo "[ -f ~/.jira_functions ] && source ~/.jira_functions" >> "$shell_file"
                updated=true
            fi
        fi
    done
    
    if [ "$updated" = true ]; then
        print_success "Shell configuration updated to source Jira functions"
    else
        print_status "Jira functions already sourced in shell configuration"
    fi
}

# Function to setup Jira integration
setup_jira_integration() {
    # Check if running in a TTY (interactive terminal)
    if [ ! -t 0 ]; then
        # Try to redirect to TTY for interactive input
        if [ -c /dev/tty ]; then
            exec < /dev/tty
        else
            print_warning "No TTY available. Jira setup will be skipped."
            print_status "Run 'g-project-setup-jira' after installation to configure Jira."
            return 0
        fi
    fi

    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    JIRA SETUP                                ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    print_status "Setting up Jira CLI integration..."
    print_status "You will be prompted for 3 pieces of information:"
    echo "  1. Your Jira host (e.g., company.atlassian.net)"
    echo "  2. Your Jira email address"
    echo "  3. Your Jira API token"
    echo ""

    # Collect Jira host
    local JIRA_HOST=""
    while [ -z "$JIRA_HOST" ]; do
        printf "Enter your Jira host (e.g., company.atlassian.net): "
        read -r JIRA_HOST
        if [ -z "$JIRA_HOST" ]; then
            print_error "This field is required"
        fi
    done

    # Collect Jira email
    local JIRA_EMAIL=""
    while [ -z "$JIRA_EMAIL" ]; do
        printf "Enter your Jira email address: "
        read -r JIRA_EMAIL
        if [ -z "$JIRA_EMAIL" ]; then
            print_error "This field is required"
        fi
    done

    # Collect API token
    echo ""
    print_status "To get your Jira API token:"
    echo "1. Go to https://id.atlassian.com/manage-profile/security/api-tokens"
    echo "2. Click 'Create API token'"
    echo "3. Give it a name (e.g., 'G-PROJECT CLI')"
    echo "4. Copy the generated token"
    echo ""

    local JIRA_API_TOKEN=""
    while [ -z "$JIRA_API_TOKEN" ]; do
        printf "Enter your Jira API token: "
        read -r -s JIRA_API_TOKEN
        echo ""
        if [ -z "$JIRA_API_TOKEN" ]; then
            print_error "This field is required"
        fi
    done

    echo ""
    print_status "Configuring Jira CLI..."

    # Create .jira.d directory
    mkdir -p "$HOME/.jira.d"

    # Store the API token securely
    echo "$JIRA_API_TOKEN" > "$HOME/.jira.d/.api_token"
    chmod 600 "$HOME/.jira.d/.api_token"

    # Create password script
    cat > "$HOME/.jira.d/pass.sh" << 'INNER_EOF'
#!/bin/bash
cat "$HOME/.jira.d/.api_token"
INNER_EOF
    chmod +x "$HOME/.jira.d/pass.sh"

    # Create config
    cat > "$HOME/.jira.d/config.yml" << INNER_EOF
endpoint: https://$JIRA_HOST
user: $JIRA_EMAIL
password-source: script
password-script: $HOME/.jira.d/pass.sh
INNER_EOF

    print_success "Jira CLI configured successfully"

    # Test connection with timeout
    print_status "Testing Jira connection..."
    if timeout 10 jira request /rest/api/2/myself >/dev/null 2>&1; then
        print_success "Jira connection successful!"
    else
        print_warning "Jira connection test failed or timed out."
        print_status "You can test the connection later by running: jira request /rest/api/2/myself"
        print_status "If there are issues, reconfigure by running 'g-project-setup-jira'"
    fi

    print_success "Jira setup completed successfully!"
    echo ""
    echo "You can now use:"
    echo "• jira list -p <PROJECT>"
    echo "• last-updates <PROJECT> '<DATE>' [--logs]"
    echo "• get-latest-changes <ISSUE> '<DATE>' [--logs]"
    return 0
}


# Function to verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    local errors=0
    
    if [ -x "$BIN_DIR/g-project" ]; then
        print_success "G-PROJECT installed successfully!"
    else
        print_error "G-PROJECT installation failed"
        errors=$((errors + 1))
    fi
    
    if command_exists jira; then
        print_success "go-jira CLI installed successfully!"
    else
        print_error "go-jira installation failed"
        errors=$((errors + 1))
    fi
    
    if [ -f "$JIRA_FUNCTIONS_FILE" ]; then
        print_success "Jira functions installed successfully!"
    else
        print_error "Jira functions installation failed"
        errors=$((errors + 1))
    fi
    
    
    if [ $errors -eq 0 ]; then
        print_success "All components installed successfully!"
        return 0
    else
        print_error "Some components failed to install"
        return 1
    fi
}

# Main installation function
main() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║          G-PROJECT INSTALLER WITH JIRA INTEGRATION          ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    print_status "Starting G-PROJECT installation with Jira CLI integration..."
    
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
    
    # Install go-jira and setup tools
    install_go_jira
    add_jira_functions
    update_shell_rc
    
    # Setup Jira integration (interactive prompt)
    setup_jira_integration
    
    # Verify installation
    verify_installation
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                   INSTALLATION COMPLETE!                     ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    # Source shell configuration files to update PATH
    print_status "Updating shell environment..."
    if [ -f "$HOME/.bashrc" ] && [[ "$SHELL" == *"bash"* ]]; then
        set +e  # Don't exit on error
        . "$HOME/.bashrc" 2>/dev/null || true
        set -e
        print_success "Sourced ~/.bashrc"
    elif [ -f "$HOME/.zshrc" ] && [[ "$SHELL" == *"zsh"* ]]; then
        set +e  # Don't exit on error
        . "$HOME/.zshrc" 2>/dev/null || true
        set -e
        print_success "Sourced ~/.zshrc"
    elif [ -f "$HOME/.profile" ]; then
        set +e  # Don't exit on error
        . "$HOME/.profile" 2>/dev/null || true
        set -e
        print_success "Sourced ~/.profile"
    fi
    
    # Update PATH for current session
    export PATH="$PATH:$BIN_DIR"
    
    # Test if commands are available
    if command_exists g-project; then
        print_success "g-project is available in PATH"
    else
        print_warning "g-project may not be in PATH. You may need to restart your terminal."
    fi
    
    if command_exists jira; then
        print_success "jira is available in PATH"
    else
        print_warning "jira may not be in PATH. You may need to restart your terminal."
    fi
    
    echo ""
    echo -e "${YELLOW}Starting G-PROJECT...${NC}"
    echo ""
    
    # Run G-PROJECT immediately
    "$BIN_DIR/g-project" || g-project
}

# Run main function
main "$@"