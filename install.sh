#!/bin/bash
# PMCodeRadar Installer for Mac/Linux
# One command to install 23 Claude Code skills for Product Managers
# Built by Boma Tai-Osagbemi | pmplaybook.ai

set -e

CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"

echo ""
echo "  =========================================="
echo "  PMCodeRadar Installer"
echo "  23 Claude Code Skills for Product Managers"
echo "  pmplaybook.ai"
echo "  =========================================="
echo ""

# Find the script's directory (where PMCodeRadar lives)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
SOURCE_SKILLS_DIR="$SCRIPT_DIR/skills"

echo "  Source:  $SCRIPT_DIR"
echo ""

# Verify we're running from a valid PMCodeRadar directory
if [ ! -d "$SOURCE_SKILLS_DIR" ]; then
    echo "  [ERROR] This doesn't look like a PMCodeRadar directory."
    echo ""
    echo "  Expected to find a skills/ folder in:"
    echo "    $SCRIPT_DIR"
    echo ""
    echo "  Make sure you're running the script from inside the PMCodeRadar folder:"
    echo "    cd /path/to/PMCodeRadar"
    echo "    ./install.sh"
    echo ""
    exit 1
fi

# Check if Claude Code directory exists
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "  [ERROR] Claude Code directory not found."
    echo ""
    echo "  Looked for: $CLAUDE_DIR"
    echo ""
    echo "  This means Claude Code isn't installed yet."
    echo "  Install it first: https://docs.anthropic.com/en/docs/claude-code"
    echo ""
    echo "  After installing Claude Code, run this script again."
    echo ""
    exit 1
fi

echo "  [1/3] Creating skills directory..."
mkdir -p "$SKILLS_DIR"

# Count source skills
SKILL_FOLDERS=$(find "$SOURCE_SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d)
TOTAL=$(echo "$SKILL_FOLDERS" | wc -l | tr -d ' ')

echo "  [2/3] Copying $TOTAL skills..."

INSTALLED=0
OVERWRITTEN=0

for SKILL_PATH in $SKILL_FOLDERS; do
    SKILL_NAME=$(basename "$SKILL_PATH")
    DEST_PATH="$SKILLS_DIR/$SKILL_NAME"

    if [ -d "$DEST_PATH" ]; then
        rm -rf "$DEST_PATH"
        OVERWRITTEN=$((OVERWRITTEN + 1))
    fi

    cp -r "$SKILL_PATH" "$DEST_PATH"
    INSTALLED=$((INSTALLED + 1))
done

echo "         $INSTALLED skills installed"
if [ "$OVERWRITTEN" -gt 0 ]; then
    echo "         $OVERWRITTEN skills updated (already existed)"
fi

# Verify installation
echo "  [3/3] Verifying installation..."
INSTALLED_COUNT=$(find "$SKILLS_DIR" -name "SKILL.md" -maxdepth 2 2>/dev/null | wc -l | tr -d ' ')

# Check key skills exist
MISSING=""
for KEY in pmcoderadar error-audit schema-explain constraint-analysis; do
    if [ ! -f "$SKILLS_DIR/$KEY/SKILL.md" ]; then
        MISSING="$MISSING $KEY"
    fi
done

echo ""

if [ -z "$MISSING" ] && [ "$INSTALLED_COUNT" -ge 23 ]; then
    echo "  =========================================="
    echo "  Installation complete!"
    echo "  =========================================="
    echo ""
    echo "  Location: $SKILLS_DIR"
    echo "  Skills:   $INSTALLED_COUNT installed"
    echo ""
    echo "  WHAT TO DO NEXT:"
    echo "  1. Close Claude Code completely (if it's open)"
    echo "  2. Open your terminal and cd into any codebase"
    echo "  3. Start Claude Code"
    echo "  4. Type:  /pmcoderadar"
    echo ""
    echo "  That's it. The pmcoderadar skill will scan your repo"
    echo "  and tell you exactly what to run next."
    echo ""
    echo "  Built by Boma Tai-Osagbemi | pmplaybook.ai"
    echo "  =========================================="
else
    echo "  =========================================="
    echo "  Installation had issues."
    echo "  =========================================="
    echo ""
    if [ -n "$MISSING" ]; then
        echo "  Missing key skills:$MISSING"
    fi
    echo "  Found $INSTALLED_COUNT skills (expected 23)"
    echo ""
    echo "  Try again or install manually - see README.md"
fi

echo ""
