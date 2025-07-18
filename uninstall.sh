#!/bin/bash

# G-PROJECT Uninstall Script
# Usage: curl -fsSL https://raw.githubusercontent.com/festoinc/g-project/main/uninstall.sh | bash
# Or: bash uninstall.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="$HOME/.g-project"
BIN_DIR="$HOME/.local/bin"
EXECUTABLE_NAME="g-project"

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

# Function to remove G-PROJECT executable
remove_executable() {
    local executable_path="$BIN_DIR/$EXECUTABLE_NAME"
    
    if [ -f "$executable_path" ]; then
        print_status "Removing G-PROJECT executable..."
        rm -f "$executable_path"
        print_success "Removed $executable_path"
    else
        print_status "G-PROJECT executable not found at $executable_path"
    fi
}

# Function to remove installation directory
remove_installation_directory() {
    if [ -d "$INSTALL_DIR" ]; then
        print_status "Removing G-PROJECT installation directory..."
        rm -rf "$INSTALL_DIR"
        print_success "Removed $INSTALL_DIR"
    else
        print_status "G-PROJECT installation directory not found at $INSTALL_DIR"
    fi
}

# Function to clean PATH entries from shell RC files
clean_path_entries() {
    local shell_files=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")
    local cleaned=false
    
    for shell_file in "${shell_files[@]}"; do
        if [ -f "$shell_file" ]; then
            # Check if the file contains G-PROJECT PATH entries
            if grep -q "# Added by G-PROJECT installer" "$shell_file" || grep -q "$BIN_DIR" "$shell_file"; then
                print_status "Cleaning PATH entries from $shell_file..."
                
                # Create a backup
                cp "$shell_file" "$shell_file.backup.$(date +%Y%m%d_%H%M%S)"
                
                # Remove G-PROJECT related lines
                # Remove the comment line and the export line that follows it
                sed -i '/# Added by G-PROJECT installer/,+1d' "$shell_file" 2>/dev/null || true
                
                # Also remove any standalone PATH entries for our bin directory
                sed -i "\|export PATH.*$BIN_DIR|d" "$shell_file" 2>/dev/null || true
                
                print_success "Cleaned $shell_file (backup created)"
                cleaned=true
            fi
            
            # Remove Jira functions source line
            if grep -q "source.*\.jira_functions" "$shell_file"; then
                print_status "Removing Jira functions from $shell_file..."
                sed -i '/# Source Jira custom functions/d' "$shell_file" 2>/dev/null || true
                sed -i '/source.*\.jira_functions/d' "$shell_file" 2>/dev/null || true
                cleaned=true
            fi
        fi
    done
    
    if [ "$cleaned" = true ]; then
        print_warning "Shell configuration files have been modified. You may need to restart your terminal or run 'source ~/.bashrc' (or ~/.zshrc) to apply changes."
    else
        print_status "No G-PROJECT PATH entries found in shell configuration files"
    fi
}

# Function to remove Jira-related files
remove_jira_components() {
    local jira_removed=false
    
    # Remove Jira functions file
    if [ -f "$HOME/.jira_functions" ]; then
        print_status "Removing Jira custom functions..."
        rm -f "$HOME/.jira_functions"
        print_success "Removed ~/.jira_functions"
        jira_removed=true
    fi
    
    # Ask about Jira CLI and config
    if [ -d "$HOME/.jira.d" ] || command_exists jira; then
        echo ""
        echo -e "${YELLOW}Jira CLI detected. Do you want to remove it?${NC}"
        echo "This will remove:"
        echo "• go-jira CLI tool"
        echo "• Jira configuration (~/.jira.d)"
        echo "• Stored credentials"
        read -p "Remove Jira CLI components? (y/N): " -n 1 -r < /dev/tty
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Remove Jira config directory
            if [ -d "$HOME/.jira.d" ]; then
                print_status "Removing Jira configuration..."
                rm -rf "$HOME/.jira.d"
                print_success "Removed ~/.jira.d"
            fi
            
            # Remove go-jira executable
            if [ -f "$BIN_DIR/jira" ]; then
                print_status "Removing go-jira CLI..."
                rm -f "$BIN_DIR/jira"
                print_success "Removed $BIN_DIR/jira"
            fi
            
            jira_removed=true
        else
            print_status "Keeping Jira CLI components"
        fi
    fi
    
    return 0
}

# Function to check for remaining G-PROJECT processes
check_running_processes() {
    if command_exists pgrep; then
        local running_processes=$(pgrep -f "g-project\|gemini\.js" 2>/dev/null || true)
        if [ ! -z "$running_processes" ]; then
            print_warning "Found running G-PROJECT processes:"
            ps -p $running_processes -o pid,cmd 2>/dev/null || true
            echo ""
            print_warning "You may want to stop these processes manually if needed."
        fi
    fi
}

# Function to verify uninstallation
verify_uninstallation() {
    print_status "Verifying uninstallation..."
    
    local issues=0
    local executable_path="$BIN_DIR/$EXECUTABLE_NAME"
    
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Installation directory still exists: $INSTALL_DIR"
        issues=$((issues + 1))
    fi
    
    if [ -f "$executable_path" ]; then
        print_warning "Executable still exists: $executable_path"
        issues=$((issues + 1))
    fi
    
    if command_exists g-project; then
        print_warning "g-project command is still available in PATH (restart terminal)"
        issues=$((issues + 1))
    fi
    
    if [ $issues -eq 0 ]; then
        print_success "G-PROJECT has been completely removed!"
        return 0
    else
        print_warning "Some components may still be present"
        return 1
    fi
}

# Function to show cleanup summary
show_cleanup_summary() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  UNINSTALL COMPLETE!                         ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}What was removed:${NC}"
    echo "• G-PROJECT installation directory: $INSTALL_DIR"
    echo "• G-PROJECT executable: $BIN_DIR/$EXECUTABLE_NAME"
    echo "• PATH entries from shell configuration files"
    
    if [ -f "$HOME/.jira_functions" ]; then
        echo "• Jira custom functions: ~/.jira_functions"
    fi
    
    echo ""
    echo -e "${BLUE}What was NOT removed:${NC}"
    echo "• Node.js and npm"
    echo "• Git"
    echo "• Any project-specific settings/settings.md files"
    echo "• Other development tools installed during setup"
    
    # Show Jira status if kept
    if [ -d "$HOME/.jira.d" ] || command_exists jira; then
        echo "• Jira CLI and configuration (kept by user choice)"
    fi
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
    echo "2. Verify removal by running: g-project --version (should fail)"
    echo ""
    echo -e "${BLUE}Need to reinstall?${NC}"
    echo "Run: curl -fsSL https://raw.githubusercontent.com/festoinc/g-project/main/install.sh | bash"
}

# Function to ask for confirmation
ask_confirmation() {
    echo -e "${YELLOW}This will remove G-PROJECT from your system.${NC}"
    echo ""
    echo "The following will be removed:"
    echo "• Installation directory: $INSTALL_DIR"
    echo "• Executable: $BIN_DIR/$EXECUTABLE_NAME"
    echo "• PATH entries from shell configuration files"
    echo ""
    echo "Node.js, Git, and other development tools will NOT be removed."
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r < /dev/tty
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Uninstall cancelled."
        exit 0
    fi
}

# Main uninstall function
main() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                   G-PROJECT UNINSTALLER                      ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check if G-PROJECT is actually installed
    if [ ! -d "$INSTALL_DIR" ] && [ ! -f "$BIN_DIR/$EXECUTABLE_NAME" ]; then
        print_warning "G-PROJECT does not appear to be installed."
        print_status "Installation directory: $INSTALL_DIR (not found)"
        print_status "Executable: $BIN_DIR/$EXECUTABLE_NAME (not found)"
        echo ""
        read -p "Continue with cleanup anyway? (y/N): " -n 1 -r < /dev/tty
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Uninstall cancelled."
            exit 0
        fi
    fi
    
    # Ask for confirmation (unless running in non-interactive mode)
    if [ -t 0 ]; then
        ask_confirmation
    fi
    
    print_status "Starting G-PROJECT uninstall..."
    echo ""
    
    # Check for running processes
    check_running_processes
    
    # Remove components
    remove_executable
    remove_installation_directory
    remove_jira_components
    clean_path_entries
    
    # Verify and show summary
    if verify_uninstallation; then
        show_cleanup_summary
    else
        echo ""
        print_warning "Uninstall completed with some issues. See messages above."
        show_cleanup_summary
    fi
}

# Handle script interruption
trap 'echo ""; print_error "Uninstall interrupted."; exit 1' INT TERM

# Run main function
main "$@"