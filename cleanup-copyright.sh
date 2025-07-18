#!/bin/bash

# Script to clean up Google copyright notices in all files
# This will replace "Copyright 2025 Google LLC" with "Copyright 2025 G-PROJECT Contributors"

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Counter for updated files
updated_files=0
total_files=0

# Function to update copyright in a file
update_copyright() {
    local file="$1"
    
    if [[ -f "$file" ]]; then
        # Check if file contains Google copyright
        if grep -q "Copyright.*Google" "$file"; then
            total_files=$((total_files + 1))
            
            # Create backup
            cp "$file" "$file.backup"
            
            # Update copyright notices
            sed -i 's/Copyright [0-9]* Google LLC/Copyright 2025 G-PROJECT Contributors/g' "$file"
            sed -i 's/Copyright [0-9]* Google Inc\./Copyright 2025 G-PROJECT Contributors/g' "$file"
            sed -i 's/Copyright [0-9]* Google/Copyright 2025 G-PROJECT Contributors/g' "$file"
            
            # Verify the change was made
            if ! grep -q "Copyright.*Google" "$file"; then
                updated_files=$((updated_files + 1))
                print_success "Updated: $file"
                # Remove backup if successful
                rm "$file.backup"
            else
                print_warning "Partial update: $file"
                # Keep backup for manual review
            fi
        fi
    fi
}

# Main function
main() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                COPYRIGHT CLEANUP SCRIPT                      ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    print_status "Starting copyright cleanup..."
    print_status "This will replace 'Copyright YYYY Google LLC' with 'Copyright 2025 G-PROJECT Contributors'"
    echo ""
    
    # Ask for confirmation
    echo -e "${YELLOW}This will modify files in the repository. Continue? (y/N)${NC}"
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_status "Operation cancelled."
        exit 0
    fi
    
    print_status "Scanning for files with Google copyright..."
    
    # Find all files with Google copyright and update them
    while IFS= read -r -d '' file; do
        update_copyright "$file"
    done < <(find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.md" \) -print0)
    
    echo ""
    print_status "Cleanup complete!"
    print_success "Updated $updated_files out of $total_files files"
    
    if [[ $updated_files -gt 0 ]]; then
        echo ""
        print_status "Files have been updated. You can now review and commit the changes."
        print_status "To see what was changed, run: git diff"
        print_status "To commit the changes, run: git add -A && git commit -m 'Update all copyright notices to G-PROJECT Contributors'"
    else
        print_warning "No files were updated. Either no Google copyright notices were found or all updates failed."
    fi
}

# Run main function
main "$@"