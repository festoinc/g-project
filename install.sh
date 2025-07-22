#!/bin/bash

# G-PROJECT Installation Script
# Usage: curl -fsSL https://raw.githubusercontent.com/festoinc/g-project/main/install.sh | bash

set -e

# Installation script version
INSTALL_VERSION="v20"

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

    # Keep all user inputs in local variables (will be destroyed when function finishes)
    local jira_host=""
    local jira_email=""
    local jira_api_token=""
    local default_project=""
    local project_directory=""

    # Collect Jira host
    while [ -z "$jira_host" ]; do
        printf "Enter your Jira host (e.g., company.atlassian.net): "
        read -r jira_host
        if [ -z "$jira_host" ]; then
            print_error "This field is required"
        fi
    done

    # Collect Jira email
    while [ -z "$jira_email" ]; do
        printf "Enter your Jira email address: "
        read -r jira_email
        if [ -z "$jira_email" ]; then
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

    while [ -z "$jira_api_token" ]; do
        printf "Enter your Jira API token: "
        read -r jira_api_token
        if [ -z "$jira_api_token" ]; then
            print_error "This field is required"
        fi
    done

    echo ""
    print_status "Configuring Jira CLI..."

    # Create .jira.d directory
    mkdir -p "$HOME/.jira.d"

    # Store the API token securely
    echo "$jira_api_token" > "$HOME/.jira.d/.api_token"
    chmod 600 "$HOME/.jira.d/.api_token"

    # Create config using environment variable approach
    cat > "$HOME/.jira.d/config.yml" << INNER_EOF
endpoint: https://$jira_host
user: $jira_email
authentication-method: api-token
INNER_EOF

    # Create environment setup script
    cat > "$HOME/.jira.d/env.sh" << 'INNER_EOF'
#!/bin/bash
export JIRA_API_TOKEN=$(cat "$HOME/.jira.d/.api_token")
INNER_EOF
    chmod +x "$HOME/.jira.d/env.sh"

    print_success "Jira CLI configured successfully"

    # Test connection with retry loop
    local connection_successful=false
    local max_attempts=3
    local attempt=1
    
    while [ "$connection_successful" = false ] && [ $attempt -le $max_attempts ]; do
        print_status "Testing Jira connection (attempt $attempt/$max_attempts)..."
        echo ""
        
        # First test with curl to validate basic auth
        print_status "🔹 STEP 1: Testing credentials with CURL..."
        print_status "  → curl -u $jira_email:*** https://$jira_host/rest/api/2/myself"
        local curl_response
        local curl_exit_code
        curl_response=$(curl -s -w "\n%{http_code}" -u "$jira_email:$jira_api_token" "https://$jira_host/rest/api/2/myself" 2>/dev/null)
        curl_exit_code=$?
        
        if [ $curl_exit_code -eq 0 ]; then
            local http_code=$(echo "$curl_response" | tail -n1)
            local response_body=$(echo "$curl_response" | sed '$d')
            
            if [ "$http_code" = "200" ]; then
                print_success "✓ Curl authentication successful (HTTP $http_code)"
                local username=$(echo "$response_body" | jq -r '.displayName // .name // "Unknown"' 2>/dev/null || echo "Unknown")
                print_status "  Authenticated as: $username"
                
                # Now test with jira CLI
                echo ""
                print_status "🔹 STEP 2: Testing with JIRA CLI..."
                print_status "  → JIRA_API_TOKEN=*** jira request /rest/api/2/myself"
                if env JIRA_API_TOKEN="$jira_api_token" jira request /rest/api/2/myself >/dev/null 2>&1; then
                    print_success "✓ Jira CLI connection successful!"
                    connection_successful=true
                else
                    print_error "✗ Jira CLI failed (but curl worked)"
                    print_status "  This suggests a Jira CLI configuration issue"
                    echo ""
                    print_status "🔍 DEBUGGING: Let's check the Jira CLI configuration..."
                    
                    # Show current config
                    if [ -f "$HOME/.jira.d/config.yml" ]; then
                        print_status "Current Jira CLI config:"
                        cat "$HOME/.jira.d/config.yml" | sed 's/password-script:.*/password-script: [HIDDEN]/'
                    else
                        print_error "Jira CLI config file not found!"
                    fi
                    
                    echo ""
                    print_status "Testing Jira CLI with verbose output and environment variable..."
                    env JIRA_API_TOKEN="$jira_api_token" jira request /rest/api/2/myself || true
                    
                    echo ""
                    print_status "Since curl authentication worked, continuing with setup..."
                    print_status "You can debug Jira CLI later if needed."
                    connection_successful=true
                fi
            else
                print_error "✗ Curl authentication failed (HTTP $http_code)"
                if [ "$http_code" = "401" ]; then
                    print_status "  → Invalid credentials (email or API token)"
                elif [ "$http_code" = "403" ]; then
                    print_status "  → Access forbidden (check permissions)"
                elif [ "$http_code" = "404" ]; then
                    print_status "  → Jira host not found (check URL)"
                else
                    print_status "  → Response: $(echo "$response_body" | head -c 200)"
                fi
            fi
        else
            print_error "✗ Curl connection failed (exit code: $curl_exit_code)"
            print_status "  → Network connectivity or DNS issue"
        fi
        
        if [ "$connection_successful" = false ]; then
            if [ $attempt -lt $max_attempts ]; then
                echo ""
                echo ""
                print_error "❌ CONNECTION FAILED - Let's try again with new credentials"
                print_status "Connection failed. This could be due to:"
                echo "  • Incorrect Jira host URL"
                echo "  • Invalid email address"
                echo "  • Wrong or expired API token"
                echo "  • Network connectivity issues"
                echo ""
                echo ""
                print_status "🔄 RETRY: Please enter your credentials again..."
                echo ""
                
                # Reset variables for retry
                jira_host=""
                jira_email=""
                jira_api_token=""
                
                # Collect Jira host again
                while [ -z "$jira_host" ]; do
                    printf "Enter your Jira host (e.g., company.atlassian.net): "
                    read -r jira_host
                    if [ -z "$jira_host" ]; then
                        print_error "This field is required"
                    fi
                done
                
                # Collect Jira email again
                while [ -z "$jira_email" ]; do
                    printf "Enter your Jira email address: "
                    read -r jira_email
                    if [ -z "$jira_email" ]; then
                        print_error "This field is required"
                    fi
                done
                
                # Collect API token again
                echo ""
                print_status "To get your Jira API token:"
                echo "1. Go to https://id.atlassian.com/manage-profile/security/api-tokens"
                echo "2. Click 'Create API token'"
                echo "3. Give it a name (e.g., 'G-PROJECT CLI')"
                echo "4. Copy the generated token"
                echo ""
                
                while [ -z "$jira_api_token" ]; do
                    printf "Enter your Jira API token: "
                    read -r jira_api_token
                    if [ -z "$jira_api_token" ]; then
                        print_error "This field is required"
                    fi
                done
                
                echo ""
                print_status "🔧 RECONFIGURING: Updating Jira CLI with new credentials..."
                
                # Update credentials
                echo "$jira_api_token" > "$HOME/.jira.d/.api_token"
                chmod 600 "$HOME/.jira.d/.api_token"
                
                # Update config
                cat > "$HOME/.jira.d/config.yml" << INNER_EOF
endpoint: https://$jira_host
user: $jira_email
authentication-method: api-token
INNER_EOF
                
                print_success "Jira CLI reconfigured with new credentials"
            else
                print_error "Maximum connection attempts reached. Installation will exit."
                print_status "Please check your credentials and try running the installation again."
                print_status "You can also run 'g-project-setup-jira' after installation to configure Jira."
                exit 1
            fi
        fi
        
        attempt=$((attempt + 1))
    done
    
    # Continue with project setup only if connection was successful
    if [ "$connection_successful" = true ]; then
        # Get project list and ask for default project
        echo ""
        print_status "Getting available Jira projects..."
        echo ""
        echo "Available projects:"
        env JIRA_API_TOKEN="$jira_api_token" jira request /rest/api/2/project | jq -r '.[] | "  " + .key + " - " + .name' 2>/dev/null || {
            print_warning "Could not retrieve project list. You can set up default project later."
        }
        
        echo ""
        while [ -z "$default_project" ]; do
            printf "Enter the default project key (e.g., AT, PROJ): "
            read -r default_project
            if [ -z "$default_project" ]; then
                print_error "This field is required"
            fi
        done
        
        # Ask for project directory
        echo ""
        local default_dir="$HOME/Documents/Projects/${default_project}_jira"
        printf "Enter project directory (default: $default_dir): "
        read -r project_directory
        
        # Use default if empty
        if [ -z "$project_directory" ]; then
            project_directory="$default_dir"
        fi
        
        # Create project directory and settings
        print_status "Creating project directory: $project_directory"
        mkdir -p "$project_directory/settings"
        
        # Create settings.md file with specified structure
        cat > "$project_directory/settings/settings.md" << SETTINGS_EOF
# Project Settings
DEFAULT_PROJECT_HANDLE=$default_project
JIRA_USER=$jira_email
LAST_STAND_UP=$(date -u -d "24 hours ago" +"%Y-%b-%d %H:%M")


#Role description
You are Jira manager. Your goal is help run all processes for the team.
Please try to provide all information in user friendly way. 
If there is any super complex technical terms explain them with simple words or nalaogies.
If there is any factual information like tiket moved from status x to status y try to provide what it mean for the business, like user xyz started verifictaion of next functionality.. 


#Running istructions 
- Do not print running logs. Just final results 
- If project in request is not mentioned use DEFAULT_PROJECT_HANDLE for pulling data 


#How to Work with Jira

jira cli is avalible in this enviroment. You can use one of the mentiotend commands:

jira --help
usage: jira [<flags>] <command> [<args> ...]

Jira Command Line Interface

Global flags:
  -h, --help                   Show context-sensitive help (also try --help-long and --help-man).
  -v, --verbose ...            Increase verbosity for debugging
  -e, --endpoint=ENDPOINT      Base URI to use for Jira
  -k, --insecure               Disable TLS certificate verification
  -Q, --quiet                  Suppress output to console
      --unixproxy=UNIXPROXY    Path for a unix-socket proxy
      --socksproxy=SOCKSPROXY  Address for a socks proxy
  -u, --user=USER              user name used within the Jira service
      --login=LOGIN            login name that corresponds to the user used for authentication

Commands:
  help:                Show help.
  version:             Prints version
  acknowledge:         Transition issue to acknowledge state
  assign:              Assign user to issue
  attach create:       Attach file to issue
  attach get:          Fetch attachment
  attach list:         Prints attachment details for issue
  attach remove:       Delete attachment
  backlog:             Transition issue to Backlog state
  block:               Mark issues as blocker
  browse:              Open issue in browser
  close:               Transition issue to close state
  comment:             Add comment to issue
  component add:       Add component
  components:          Show components for a project
  create:              Create issue
  createmeta:          View 'create' metadata
  done:                Transition issue to Done state
  dup:                 Mark issues as duplicate
  edit:                Edit issue details
  editmeta:            View 'edit' metadata
  epic add:            Add issues to Epic
  epic create:         Create Epic
  epic list:           Prints list of issues for an epic with optional search criteria
  epic remove:         Remove issues from Epic
  export-templates:    Export templates for customizations
  fields:              Prints all fields, both System and Custom
  in-progress:         Transition issue to Progress state
  issuelink:           Link two issues
  issuelinktypes:      Show the issue link types
  issuetypes:          Show issue types for a project
  labels add:          Add labels to an issue
  labels remove:       Remove labels from an issue
  labels set:          Set labels on an issue
  list:                Prints list of issues for given search criteria
  login:               Attempt to login into jira server
  logout:              Deactivate session with Jira server
  rank:                Mark issues as blocker
  reopen:              Transition issue to reopen state
  request:             Open issue in requestr
  resolve:             Transition issue to resolve state
  start:               Transition issue to start state
  stop:                Transition issue to stop state
  subtask:             Subtask issue
  take:                Assign issue to yourself
  todo:                Transition issue to To Do state
  transition:          Transition issue to given state
  transitions:         List valid issue transitions
  transmeta:           List valid issue transitions
  unassign:            Unassign an issue
  unexport-templates:  Remove unmodified exported templates
  view:                Prints issue details
  vote:                Vote up/down an issue
  watch:               Add/Remove watcher to issue
  worklog add:         Add a worklog to an issue
  worklog list:        Prints the worklog data for given issue
  session:             Attempt to login into jira server
SETTINGS_EOF
        
        print_success "Project settings created at: $project_directory/settings/settings.md"
        
        # Create validation file for the project
        print_status "Creating validation rules for project: $default_project"
        cat > "$project_directory/settings/${default_project}_validation.json" << VALIDATION_EOF
{
  "In Progress": ["original_estimate_not_empty"]
}
VALIDATION_EOF
        
        print_success "Validation rules created at: $project_directory/settings/${default_project}_validation.json"
        
        # Create custom_commands directory with example files
        print_status "Creating custom_commands directory with examples..."
        mkdir -p "$project_directory/custom_commands"
        
        # Create planning command example
        cat > "$project_directory/custom_commands/planning" << 'PLANNING_EOF'
-Ask user to provide task ids that team plans to dliver this week.
-Ask user to provide task ids that will be worked on but not planned to be relesead this week 
-run date +%V to get week of the year number
-create lablel week_{week_of_the_year}_to_release and apply ot tasks that would be released 
-create lablel week_{week_of_the_year}_progress and apply ot tasks that would be worked on
-print summary
PLANNING_EOF
        
        # Create stand-up command example
        cat > "$project_directory/custom_commands/stand-up" << 'STANDUP_EOF'
- run last-updates {project_handle} {last_standup} it will give you list of the tasks that was changed since last stand-up
- iterate theough each task and run get-latest-changes {task_handle} {last_standup} it will give you changes that happened to task since last stand-up
-  Based on information you collected please prepare stand-up report draft to explain what team have been doing since last stand-up.
- run  date -u 
- update /settings/settings.md last standup with   date -u 


STANDUP_EOF
        
        print_success "Custom commands created at: $project_directory/custom_commands/"
        
        # Setup JIRA_API_TOKEN in shell profile for convenient CLI usage
        echo ""
        print_status "🔧 Setting up Jira CLI environment variable..."
        
        local jira_env_line='export JIRA_API_TOKEN=$(cat ~/.jira.d/.api_token)'
        local shell_updated=false
        
        # Check current shell and add to appropriate profile
        if [[ "$SHELL" == *"bash"* ]] && [ -f "$HOME/.bashrc" ]; then
            # Check if already exists to avoid duplicates
            if ! grep -q "JIRA_API_TOKEN.*\.jira\.d" "$HOME/.bashrc" 2>/dev/null; then
                echo "" >> "$HOME/.bashrc"
                echo "# Jira CLI API Token (added by G-PROJECT installer)" >> "$HOME/.bashrc"
                echo "$jira_env_line" >> "$HOME/.bashrc"
                print_success "✓ Added JIRA_API_TOKEN to ~/.bashrc"
                shell_updated=true
            else
                print_status "JIRA_API_TOKEN already exists in ~/.bashrc"
            fi
        elif [[ "$SHELL" == *"zsh"* ]] && [ -f "$HOME/.zshrc" ]; then
            # Check if already exists to avoid duplicates
            if ! grep -q "JIRA_API_TOKEN.*\.jira\.d" "$HOME/.zshrc" 2>/dev/null; then
                echo "" >> "$HOME/.zshrc"
                echo "# Jira CLI API Token (added by G-PROJECT installer)" >> "$HOME/.zshrc"
                echo "$jira_env_line" >> "$HOME/.zshrc"
                print_success "✓ Added JIRA_API_TOKEN to ~/.zshrc"
                shell_updated=true
            else
                print_status "JIRA_API_TOKEN already exists in ~/.zshrc"
            fi
        else
            # Fallback to .profile for other shells
            if ! grep -q "JIRA_API_TOKEN.*\.jira\.d" "$HOME/.profile" 2>/dev/null; then
                echo "" >> "$HOME/.profile"
                echo "# Jira CLI API Token (added by G-PROJECT installer)" >> "$HOME/.profile"
                echo "$jira_env_line" >> "$HOME/.profile"
                print_success "✓ Added JIRA_API_TOKEN to ~/.profile"
                shell_updated=true
            else
                print_status "JIRA_API_TOKEN already exists in ~/.profile"
            fi
        fi
        
        if [ "$shell_updated" = true ]; then
            print_status "After installation, you can use jira commands directly:"
            echo "  • jira request /rest/api/2/myself"
            echo "  • jira request /rest/api/2/project"
            echo "  • jira list -p $default_project"
            print_status "Restart your terminal or run 'source ~/.bashrc' (or ~/.zshrc) to activate"
        fi
        
        # Export the project directory for use in main function
        export G_PROJECT_DIR="$project_directory"
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
    
    print_status "Running installation version $INSTALL_VERSION"
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
    
    # Change to project directory if it was set during Jira setup
    if [ -n "$G_PROJECT_DIR" ] && [ -d "$G_PROJECT_DIR" ]; then
        print_status "Changing to project directory: $G_PROJECT_DIR"
        cd "$G_PROJECT_DIR"
    fi
    
    # Run G-PROJECT immediately
    "$BIN_DIR/g-project" || g-project
}

# Run main function
main "$@"