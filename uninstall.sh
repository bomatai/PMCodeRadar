#!/usr/bin/env bash
# PMCodeRadar Uninstaller for Mac/Linux
# Removes all 23 PMCodeRadar skill folders from ~/.claude/skills/
# Does NOT remove any other skills the user may have installed.

set -e

SKILLS_DIR="$HOME/.claude/skills"

PM_SKILLS=(
    "setup"
    "constraint-analysis"
    "debt-cost-estimate"
    "pre-ship-scan"
    "dead-code-audit"
    "event-inventory"
    "duplicate-check"
    "schema-explain"
    "error-audit"
    "api-surface-map"
    "onboarding-audit"
    "validation-audit"
    "route-audit"
    "notification-audit"
    "search-audit"
    "architecture-map"
    "removal-impact"
    "privacy-audit"
    "flag-audit"
    "dependency-map"
    "migration-risk"
    "catalog" "feedback"
)

echo ""
echo "========================================"
echo "  PMCodeRadar Uninstaller"
echo "========================================"
echo ""

if [ ! -d "$SKILLS_DIR" ]; then
    echo "Skills directory not found: $SKILLS_DIR"
    echo "Nothing to uninstall."
    exit 0
fi

# Find which PMCodeRadar skills are currently installed
found=()
not_found=()

for skill in "${PM_SKILLS[@]}"; do
    if [ -d "$SKILLS_DIR/$skill" ]; then
        found+=("$skill")
    else
        not_found+=("$skill")
    fi
done

if [ ${#found[@]} -eq 0 ]; then
    echo "No PMCodeRadar skills found in $SKILLS_DIR"
    echo "Nothing to uninstall."
    exit 0
fi

echo "The following ${#found[@]} PMCodeRadar skill folders will be REMOVED:"
echo ""
for skill in "${found[@]}"; do
    echo "  - $skill"
done
echo ""

if [ ${#not_found[@]} -gt 0 ]; then
    echo "Not found (already removed or never installed):"
    for skill in "${not_found[@]}"; do
        echo "  - $skill"
    done
    echo ""
fi

read -r -p "Are you sure you want to remove these skills? (y/n) " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo ""
    echo "Uninstall cancelled. No files were removed."
    exit 0
fi

echo ""
removed=0
errors=0

for skill in "${found[@]}"; do
    if rm -rf "$SKILLS_DIR/$skill" 2>/dev/null; then
        echo "  Removed: $skill"
        removed=$((removed + 1))
    else
        echo "  FAILED:  $skill"
        errors=$((errors + 1))
    fi
done

echo ""
echo "========================================"
echo "  Uninstall complete"
echo "  Removed: $removed / ${#found[@]} skills"
if [ "$errors" -gt 0 ]; then
    echo "  Errors:  $errors"
fi
echo "========================================"
echo ""
echo "Your other Claude Code skills were not touched."
echo "To reinstall PMCodeRadar, run: bash install.sh"
