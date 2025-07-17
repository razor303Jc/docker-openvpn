#!/bin/bash

#
# Script Security Validation
# Checks shell scripts for common security issues
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXIT_CODE=0

echo "Checking shell scripts for security issues..."

# Find all shell scripts
SCRIPTS=$(find "$SCRIPT_DIR" -name "*.sh" -o -path "*/bin/*" -type f | grep -v ".git")

check_script() {
    local script="$1"
    local issues=0
    
    echo "Checking: $script"
    
    # Check for set -e (exit on error)
    if ! grep -q "set -e" "$script"; then
        echo "  ⚠️  Missing 'set -e' for error handling"
        ((issues++))
    fi
    
    # Check for unquoted variables
    if grep -q '\$[A-Za-z_][A-Za-z0-9_]*[^"]' "$script" 2>/dev/null; then
        echo "  ⚠️  Potentially unquoted variables found"
        ((issues++))
    fi
    
    # Check for dangerous commands
    if grep -q -E "(eval|exec|\$\(.*\))" "$script"; then
        echo "  ⚠️  Potentially dangerous command usage found"
        ((issues++))
    fi
    
    # Check for hardcoded credentials
    if grep -q -i -E "(password|secret|key|token).*=" "$script"; then
        echo "  ⚠️  Potential hardcoded credentials found"
        ((issues++))
    fi
    
    # Check for proper shebang
    if ! head -n1 "$script" | grep -q "^#!/bin/bash"; then
        echo "  ⚠️  Missing or incorrect shebang"
        ((issues++))
    fi
    
    if [ $issues -eq 0 ]; then
        echo "  ✅ No issues found"
    else
        EXIT_CODE=1
    fi
    
    echo ""
}

for script in $SCRIPTS; do
    if [ -f "$script" ]; then
        check_script "$script"
    fi
done

if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ All scripts passed security checks"
else
    echo "❌ Some scripts have security issues that should be reviewed"
fi

exit $EXIT_CODE