#!/bin/bash

# G-PROJECT Uninstaller Script
# Usage: curl -fsSL https://raw.githubusercontent.com/festoinc/g-project/main/uninstall.sh | bash

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
EXECUTABLE="$BIN_DIR/g-project"

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

# Function to remove G-PROJECT installation
remove_g_project() {
    print_status "Removing G-PROJECT installation..."
    
    # Remove installation directory
    if [ -d "$INSTALL_DIR" ]; then
        print_status "Removing $INSTALL_DIR..."
        rm -rf "$INSTALL_DIR"
        print_success "Installation directory removed"
    else
        print_warning "Installation directory not found: $INSTALL_DIR"
    fi
    
    # Remove executable
    if [ -f "$EXECUTABLE" ]; then
        print_status "Removing executable $EXECUTABLE..."
        rm -f "$EXECUTABLE"
        print_success "Executable removed"
    else
        print_warning "Executable not found: $EXECUTABLE"
    fi
}

# Function to remove PATH entry
remove_from_path() {
    print_status "Checking PATH entries..."
    
    local shell_files=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")
    local removed=false
    
    for shell_file in "${shell_files[@]}"; do
        if [ -f "$shell_file" ]; then
            # Check if the PATH entry exists
            if grep -q "Added by G-PROJECT installer" "$shell_file"; then
                print_status "Removing PATH entry from $shell_file..."
                
                # Create a backup
                cp "$shell_file" "$shell_file.backup"
                
                # Remove the G-PROJECT PATH entry
                sed -i '/# Added by G-PROJECT installer/,+1d' "$shell_file"
                
                print_success "PATH entry removed from $shell_file"
                removed=true
            fi
        fi
    done
    
    if [ "$removed" = false ]; then
        print_warning "No G-PROJECT PATH entries found in shell configuration files"
    fi
}

# Function to clean up remaining files
cleanup_remaining() {
    print_status "Cleaning up remaining files..."
    
    # Remove any remaining symlinks
    find "$BIN_DIR" -name "g-project*" -type l -delete 2>/dev/null || true
    
    # Remove empty directories
    if [ -d "$BIN_DIR" ] && [ -z "$(ls -A "$BIN_DIR")" ]; then
        rmdir "$BIN_DIR"
        print_status "Removed empty directory: $BIN_DIR"
    fi
    
    print_success "Cleanup completed"
}

# Function to verify uninstallation
verify_uninstallation() {
    print_status "Verifying uninstallation..."
    
    local issues=0
    
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Installation directory still exists: $INSTALL_DIR"
        issues=$((issues + 1))
    fi
    
    if [ -f "$EXECUTABLE" ]; then
        print_warning "Executable still exists: $EXECUTABLE"
        issues=$((issues + 1))
    fi
    
    if command -v g-project >/dev/null 2>&1; then
        print_warning "g-project command is still available (may need to restart terminal)"
        issues=$((issues + 1))
    fi
    
    if [ $issues -eq 0 ]; then
        print_success "G-PROJECT has been completely removed!"
    else
        print_warning "Some issues were found during uninstallation"
    fi
}

# Main uninstallation function
main() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                   G-PROJECT UNINSTALLER                      ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    print_status "Starting G-PROJECT uninstallation..."
    
    # Ask for confirmation
    echo -e "${YELLOW}This will remove G-PROJECT from your system.${NC}"
    echo -e "${YELLOW}Are you sure you want to continue? (y/N)${NC}"
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_status "Uninstallation cancelled."
        exit 0
    fi
    
    # Remove G-PROJECT
    remove_g_project
    
    # Remove PATH entries
    remove_from_path
    
    # Clean up remaining files
    cleanup_remaining
    
    # Verify uninstallation
    verify_uninstallation
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                 UNINSTALLATION COMPLETE!                     ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Note:${NC} You may need to restart your terminal for PATH changes to take effect."
    echo ""
    echo -e "${BLUE}Thank you for using G-PROJECT!${NC}"
}

# Run main function
main "$@"