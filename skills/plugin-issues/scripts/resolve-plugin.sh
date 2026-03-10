#!/bin/bash
# resolve-plugin.sh — Resolve a plugin name to its GitHub repository
# Usage: bash resolve-plugin.sh <plugin-name>
#
# Searches marketplace.json files to find which marketplace and repository
# a plugin belongs to. Returns JSON on stdout, errors on stderr.
#
# Search order:
#   1. ~/.claude/plugins/marketplaces/*/.claude-plugin/marketplace.json
#   2. Sibling directories of COGNI_WORKSPACE_ROOT (dev monorepos)
#
# Compatible with bash 3.2 (macOS default). Uses python3 for JSON parsing.

set -euo pipefail

PLUGIN_NAME="${1:-}"

if [ -z "$PLUGIN_NAME" ]; then
  echo "Usage: bash $0 <plugin-name>" >&2
  exit 1
fi

# Collect marketplace.json paths to search
MARKETPLACE_FILES=()

# Source 1: Installed marketplaces cache
CACHE_DIR="$HOME/.claude/plugins/marketplaces"
if [ -d "$CACHE_DIR" ]; then
  for mp in "$CACHE_DIR"/*/.claude-plugin/marketplace.json; do
    [ -f "$mp" ] && MARKETPLACE_FILES+=("$mp")
  done
fi

# Source 2: Sibling directories of COGNI_WORKSPACE_ROOT (dev monorepos)
if [ -n "${COGNI_WORKSPACE_ROOT:-}" ]; then
  PARENT_DIR="$(dirname "$(dirname "$COGNI_WORKSPACE_ROOT")")"
  for sibling in "$PARENT_DIR"/*/.claude-plugin/marketplace.json; do
    [ -f "$sibling" ] && MARKETPLACE_FILES+=("$sibling")
  done
fi

# Source 3: Also check common dev locations as fallback
for dev_path in \
  "$HOME/GitHub/dev/cogni-works/.claude-plugin/marketplace.json" \
  "$HOME/GitHub/dev/cogni-works-pro/.claude-plugin/marketplace.json"; do
  if [ -f "$dev_path" ]; then
    # Avoid duplicates
    already=false
    for existing in "${MARKETPLACE_FILES[@]+"${MARKETPLACE_FILES[@]}"}"; do
      [ "$existing" = "$dev_path" ] && already=true && break
    done
    $already || MARKETPLACE_FILES+=("$dev_path")
  fi
done

if [ ${#MARKETPLACE_FILES[@]} -eq 0 ]; then
  echo '{"error":"no marketplace files found","plugin":"'"$PLUGIN_NAME"'"}' >&2
  exit 1
fi

# Build a newline-separated list of paths for python
MP_LIST=""
for mp in "${MARKETPLACE_FILES[@]}"; do
  MP_LIST="${MP_LIST}${mp}"$'\n'
done

# Use python3 to parse JSON and find the plugin
echo "$MP_LIST" | python3 -c "
import json, sys, os

plugin_name = '$PLUGIN_NAME'
mp_paths = [p.strip() for p in sys.stdin.readlines() if p.strip()]

results = []
for mp_path in mp_paths:
    try:
        with open(mp_path) as f:
            data = json.load(f)
    except (json.JSONDecodeError, FileNotFoundError):
        continue

    marketplace_name = data.get('name', 'unknown')
    for plugin in data.get('plugins', []):
        if plugin.get('name') == plugin_name:
            repo_url = plugin.get('repository', '')
            # Convert https://github.com/owner/repo to owner/repo
            owner_repo = repo_url.replace('https://github.com/', '').rstrip('/')
            results.append({
                'plugin': plugin_name,
                'repository': repo_url,
                'owner_repo': owner_repo,
                'marketplace': marketplace_name,
                'marketplace_path': mp_path,
                'version': plugin.get('version', 'unknown'),
                'license': plugin.get('license', 'unknown')
            })

# Deduplicate: same owner_repo from different paths is the same plugin
seen = {}
for r in results:
    key = r['owner_repo']
    if key not in seen:
        seen[key] = r

results = list(seen.values())

if len(results) == 0:
    print(json.dumps({'error': 'plugin not found', 'plugin': plugin_name, 'searched': len(mp_paths)}))
    sys.exit(1)
elif len(results) == 1:
    result = results[0]
    result['ambiguous'] = False
    print(json.dumps(result))
else:
    print(json.dumps({
        'plugin': plugin_name,
        'ambiguous': True,
        'matches': results
    }))
"
