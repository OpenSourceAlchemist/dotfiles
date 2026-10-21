#!/bin/bash
# Run gitleaks secret detection
# Usage: ./scripts/run-gitleaks.sh [--staged|--all]

set -e

if ! command -v gitleaks >/dev/null 2>&1; then
    echo "⚠️  gitleaks not found. Skipping secret scan."
    echo "   Install gitleaks (https://github.com/gitleaks/gitleaks) to enable secret detection."
    exit 0
fi

if [ "$1" = "--all" ]; then
    exec gitleaks detect --no-git --source . --redact --verbose
elif [ "$1" = "--staged" ]; then
    exec gitleaks protect --staged --redact --verbose
else
    # Default: if staged changes exist, protect staged; otherwise scan workspace
    if git diff --cached --quiet 2>/dev/null; then
        exec gitleaks detect --no-git --source . --redact --verbose
    else
        exec gitleaks protect --staged --redact --verbose
    fi
fi
