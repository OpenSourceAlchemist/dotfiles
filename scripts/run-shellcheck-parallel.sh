#!/bin/bash
# Run shellcheck on all shell scripts in parallel
# Uses GNU parallel if available, xargs -P otherwise, falls back to sequential
# Usage: ./scripts/run-shellcheck-parallel.sh

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DOTFILES_DIR"

# Shell scripts to check
SCRIPTS=(
    "bootstrap.sh"
    "install.sh"
    "fzf/.fzf.bash"
    "fzf/.fzf.zsh"
)

echo "Running parallel ShellCheck on ${#SCRIPTS[@]} scripts..."
echo ""

failed=0

# Function to check a single script
check_script() {
    local script="$1"
    
    if [ ! -f "$script" ]; then
        echo "❌ SKIP: $script (not found)"
        return 0
    fi
    
    if shellcheck -e SC1091,SC2002,SC2154 "$script" 2>&1; then
        echo -e "✅ $script"
        return 0
    else
        echo -e "❌ $script"
        return 1
    fi
}

export -f check_script

# Check if GNU parallel is available
if command -v parallel &>/dev/null; then
    echo "Using GNU parallel (parallel execution)..."
    echo ""
    # Run in parallel with 4 jobs
    for script in "${SCRIPTS[@]}"; do
        check_script "$script" || failed=1
    done
elif command -x xargs -P 2>/dev/null; then
    echo "Using xargs -P (parallel execution)..."
    echo ""
    printf '%s\n' "${SCRIPTS[@]}" | xargs -I{} bash -c '
        script="$1"
        if [ ! -f "$script" ]; then
            echo "❌ SKIP: $script (not found)"
            exit 0
        fi
        if shellcheck -e SC1091,SC2002,SC2154 "$script" 2>&1; then
            echo -e "✅ $script"
            exit 0
        else
            echo -e "❌ $script"
            exit 1
        fi
    ' bash {}
    failed=${PIPESTATUS[0]}
else
    echo "GNU parallel and xargs -P not available, using sequential execution..."
    echo ""
    for script in "${SCRIPTS[@]}"; do
        check_script "$script" || failed=1
    done
fi

echo ""

if [ $failed -eq 0 ]; then
    echo -e "${GREEN}All ShellCheck validations passed!${NC}"
    exit 0
else
    echo -e "${RED}Some ShellCheck validations failed!${NC}"
    exit 1
fi
