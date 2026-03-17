#!/bin/bash
# Bump blox-skills version across all files that contain it
# Usage: ./scripts/bump-version.sh [major|minor|patch]
# Default: patch

set -e

TYPE="${1:-patch}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Read current version from plugin.json
CURRENT=$(grep '"version"' "$ROOT/.claude-plugin/plugin.json" | head -1 | sed 's/.*"version": *"\([^"]*\)".*/\1/')

if [ -z "$CURRENT" ]; then
  echo "Error: Could not read current version from .claude-plugin/plugin.json"
  exit 1
fi

# Parse version parts
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"

# Bump
case "$TYPE" in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  patch) PATCH=$((PATCH + 1)) ;;
  *)
    echo "Usage: $0 [major|minor|patch]"
    echo "Current version: $CURRENT"
    exit 1
    ;;
esac

NEW="$MAJOR.$MINOR.$PATCH"

echo "Bumping version: $CURRENT → $NEW ($TYPE)"

# Update all version files
FILES=(
  "$ROOT/.claude-plugin/plugin.json"
  "$ROOT/.claude-plugin/marketplace.json"
  "$ROOT/.sync/plugin.json"
  "$ROOT/.sync/marketplace.json"
)

for FILE in "${FILES[@]}"; do
  if [ -f "$FILE" ]; then
    sed -i '' "s/\"version\": \"$CURRENT\"/\"version\": \"$NEW\"/" "$FILE"
    echo "  ✅ $FILE"
  else
    echo "  ⏭️  $FILE (not found, skipped)"
  fi
done

echo ""
echo "Version bumped to $NEW"
echo "Run: git add -A && git commit -m \"chore: bump version $CURRENT → $NEW\" && git push origin main"
