#!/bin/bash
# issue-store.sh — JSON state management for plugin issues
# Usage: bash issue-store.sh <command> [args...]
#
# Commands requiring <working_dir>:
#   init <working_dir>                    Initialize cogni-issues/ workspace
#   add <working_dir> <json>              Add an issue record (JSON on arg or stdin)
#   read <working_dir>                    Read issues.json to stdout
#   update-status <working_dir> <id> <status> [github_url]  Update issue status
#
# Standalone commands:
#   gen-id                                Generate an issue UUID
#
# All output is JSON on stdout. Errors go to stderr.
# Compatible with bash 3.2 (macOS default).
#
# JSON FORMAT ASSUMPTION: This script expects pretty-printed JSON with one
# field per line (as produced by Claude's Write tool).

set -euo pipefail

COMMAND="${1:-}"

usage() {
  echo "Usage: bash $0 <command> [args...]" >&2
  echo "Commands: init <dir>, gen-id, add <dir> <json>, read <dir>, update-status <dir> <id> <status> [github_url]" >&2
  exit 1
}

# Generate a UUID v4 (portable, no external deps)
gen_uuid() {
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen | tr '[:upper:]' '[:lower:]'
  else
    od -x /dev/urandom | head -1 | awk '{print $2$3"-"$4"-4"substr($5,2)"-"$6"-"$7$8$9}'
  fi
}

case "$COMMAND" in
  init)
    WORKING_DIR="${2:-}"
    [ -z "$WORKING_DIR" ] && usage
    ISSUES_DIR="$WORKING_DIR/cogni-issues"
    mkdir -p "$ISSUES_DIR"
    if [ ! -f "$ISSUES_DIR/issues.json" ]; then
      NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
      cat > "$ISSUES_DIR/issues.json" <<ENDJSON
{
  "version": "1.0.0",
  "updated_at": "$NOW",
  "issues": []
}
ENDJSON
      echo "{\"status\":\"initialized\",\"path\":\"$ISSUES_DIR\"}"
    else
      echo "{\"status\":\"exists\",\"path\":\"$ISSUES_DIR\"}"
    fi
    ;;

  gen-id)
    UUID=$(gen_uuid)
    echo "{\"id\":\"issue-$UUID\"}"
    ;;

  add)
    WORKING_DIR="${2:-}"
    [ -z "$WORKING_DIR" ] && usage
    ISSUES_FILE="$WORKING_DIR/cogni-issues/issues.json"
    if [ ! -f "$ISSUES_FILE" ]; then
      echo "{\"error\":\"issues.json not found — run init first\",\"path\":\"$ISSUES_FILE\"}" >&2
      exit 1
    fi
    # Issue JSON passed as arg 3 or via stdin
    ISSUE_JSON="${3:-}"
    if [ -z "$ISSUE_JSON" ]; then
      ISSUE_JSON=$(cat)
    fi
    # Use python3 to append the issue to the array
    python3 -c "
import json, sys
with open('$ISSUES_FILE') as f:
    data = json.load(f)
issue = json.loads('''$ISSUE_JSON''')
data['issues'].append(issue)
from datetime import datetime, timezone
data['updated_at'] = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
with open('$ISSUES_FILE', 'w') as f:
    json.dump(data, f, indent=2)
print(json.dumps({'status': 'added', 'id': issue.get('id', 'unknown'), 'total': len(data['issues'])}))
"
    ;;

  read)
    WORKING_DIR="${2:-}"
    [ -z "$WORKING_DIR" ] && usage
    ISSUES_FILE="$WORKING_DIR/cogni-issues/issues.json"
    if [ -f "$ISSUES_FILE" ]; then
      cat "$ISSUES_FILE"
    else
      echo "{\"error\":\"issues.json not found\",\"path\":\"$ISSUES_FILE\"}" >&2
      exit 1
    fi
    ;;

  update-status)
    WORKING_DIR="${2:-}"
    ISSUE_ID="${3:-}"
    NEW_STATUS="${4:-}"
    GITHUB_URL="${5:-}"
    [ -z "$WORKING_DIR" ] || [ -z "$ISSUE_ID" ] || [ -z "$NEW_STATUS" ] && usage
    ISSUES_FILE="$WORKING_DIR/cogni-issues/issues.json"
    if [ ! -f "$ISSUES_FILE" ]; then
      echo "{\"error\":\"issues.json not found\"}" >&2
      exit 1
    fi
    python3 -c "
import json
with open('$ISSUES_FILE') as f:
    data = json.load(f)
found = False
for issue in data['issues']:
    if issue.get('id') == '$ISSUE_ID':
        issue['status'] = '$NEW_STATUS'
        github_url = '$GITHUB_URL'
        if github_url:
            issue['github_url'] = github_url
        from datetime import datetime, timezone
        issue['updated_at'] = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
        data['updated_at'] = issue['updated_at']
        found = True
        break
if not found:
    print(json.dumps({'error': 'issue not found', 'id': '$ISSUE_ID'}))
    import sys; sys.exit(1)
with open('$ISSUES_FILE', 'w') as f:
    json.dump(data, f, indent=2)
print(json.dumps({'status': 'updated', 'id': '$ISSUE_ID', 'new_status': '$NEW_STATUS'}))
"
    ;;

  *)
    usage
    ;;
esac
